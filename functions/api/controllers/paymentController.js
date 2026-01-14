const { admin, db } = require('../config/firebase');
const { getCashfreeConfig } = require('../config/cashfree');
const { sendNotification } = require('../utils/notificationService');
const axios = require('axios');

exports.createPaymentOrder = async (req, res) => {
    try {
        const { orderId, amount, customerId, customerPhone, customerEmail, projectId, type } = req.body;
        const userId = req.uid;

        // Validation
        if (!orderId || !amount || amount <= 0 || !customerId || !customerEmail || !customerPhone) {
            return res.status(400).json({ success: false, message: "Missing or invalid required fields." });
        }

        if (customerId !== userId) {
            return res.status(403).json({ success: false, message: "Permission denied. Customer ID mismatch." });
        }

        const config = getCashfreeConfig();

        const url = `${config.baseUrl}/orders`;
        const headers = {
            'Content-Type': 'application/json',
            'x-client-id': config.appId,
            'x-client-secret': config.secretKey,
            'x-api-version': config.apiVersion,
        };

        const requestBody = {
            order_id: orderId,
            order_amount: amount,
            order_currency: "INR",
            customer_details: {
                customer_id: customerId,
                customer_phone: customerPhone,
                customer_email: customerEmail,
            },
            order_meta: {
                // In a real deployment, replace with your actual return URL
                return_url: `https://work-hub-c31ef.web.app/payment-return?order_id=${orderId}`,
            },
        };

        const response = await axios.post(url, requestBody, { headers });

        if (response.data) {
            // Audit Trail
            await db.collection("payment_orders").doc(orderId).set({
                orderId: orderId,
                userId: userId,
                amount: amount,
                currency: "INR",
                status: "created",
                type: type || "unknown",
                projectId: projectId || null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                customerEmail: customerEmail,
                customerPhone: customerPhone,
            });

            return res.json({
                success: true,
                paymentSessionId: response.data.payment_session_id,
                orderId: orderId,
            });
        }
    } catch (error) {
        console.error("Create Order Error:", error.response?.data || error.message);

        // RETURN ACTUAL ERROR MESSAGE SO FLUTTER SEES IT
        const detailedError = error.response?.data?.message || error.message || "Unknown Error";
        const msg = `Payment Failed: ${detailedError}`;

        res.status(500).json({
            success: false,
            message: msg,
            error: error.response?.data || error.message
        });
    }
};

exports.verifyPaymentStatus = async (req, res) => {
    try {
        const { orderId } = req.body;
        const userId = req.uid;

        if (!orderId) return res.status(400).json({ success: false, message: "Missing orderId" });

        const orderRef = db.collection("payment_orders").doc(orderId);
        const orderDoc = await orderRef.get();

        if (!orderDoc.exists) return res.status(404).json({ success: false, message: "Order not found" });
        if (orderDoc.data().userId !== userId) return res.status(403).json({ success: false, message: "Permission denied" });

        const config = getCashfreeConfig();
        const url = `${config.baseUrl}/orders/${orderId}`;
        const headers = {
            'Content-Type': 'application/json',
            'x-client-id': config.appId,
            'x-client-secret': config.secretKey,
            'x-api-version': config.apiVersion,
        };

        const response = await axios.get(url, { headers });
        const data = response.data;

        if (data) {
            const orderStatus = data.order_status;
            const isPaid = orderStatus === "PAID";

            await orderRef.update({
                status: orderStatus.toLowerCase(),
                verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
                paymentDetails: {
                    orderStatus: orderStatus,
                    orderAmount: data.order_amount,
                    orderCurrency: data.order_currency,
                },
            });

            // Update Project if Escrow
            const orderData = orderDoc.data();
            if (isPaid && orderData.type === 'escrow_deposit' && orderData.projectId) {
                await db.runTransaction(async (transaction) => {
                    const freshOrderDoc = await transaction.get(orderRef);
                    if (freshOrderDoc.data().isProcessed) return;

                    const projectRef = db.collection("projects").doc(orderData.projectId);
                    const projectDoc = await transaction.get(projectRef);

                    transaction.update(projectRef, {
                        'escrowBalance': admin.firestore.FieldValue.increment(orderData.amount)
                    });

                    transaction.update(orderRef, {
                        isProcessed: true,
                        processedAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    // NOTIFICATION: Escrow Funded
                    if (projectDoc.exists) {
                        const workerId = projectDoc.data().workerId;
                        return workerId;
                    }
                }).then(async (workerId) => {
                    if (workerId) {
                        await sendNotification(
                            workerId,
                            "Escrow Funded! 💰",
                            `The client has deposited ₹${orderData.amount} into escrow. You can start working!`,
                            { projectId: orderData.projectId },
                            "escrow_funded"
                        );
                    }
                });
            }

            return res.json({
                success: true,
                isPaid: isPaid,
                orderStatus: orderStatus,
                orderId: orderId
            });
        }
    } catch (error) {
        console.error("Verify Payment Error:", error.response?.data || error.message);
        res.status(500).json({ success: false, message: "Verification failed", error: error.message });
    }
};

exports.releasePayment = async (req, res) => {
    try {
        const { projectId, amount: rawAmount } = req.body;
        const amount = parseFloat(rawAmount);
        const userId = req.uid;

        if (!projectId || !amount || amount <= 0) {
            return res.status(400).json({ success: false, message: "Invalid project ID or amount" });
        }

        const projectRef = db.collection("projects").doc(projectId);

        let workerId = null;

        await db.runTransaction(async (transaction) => {
            const projectDoc = await transaction.get(projectRef);
            if (!projectDoc.exists) throw new Error("Project not found");

            const projectData = projectDoc.data();
            if (projectData.ownerId !== userId) throw new Error("Permission denied. Only owner can release.");

            const escrowBalance = projectData.escrowBalance || 0;
            if (amount > escrowBalance) throw new Error(`Insufficient escrow balance: ${escrowBalance}`);

            workerId = projectData.workerId;
            if (!workerId) throw new Error("No worker assigned");

            let commissionRate = 0.10;
            const settingsDoc = await transaction.get(db.collection("platform_settings").doc("revenue"));
            if (settingsDoc.exists) commissionRate = settingsDoc.data().commissionRate || 0.10;

            const platformFee = amount * commissionRate;
            const netEarnings = amount - platformFee;
            const paymentId = Date.now().toString();

            transaction.update(projectRef, {
                [`payments.${paymentId}`]: {
                    amount, status: 'released', releasedAt: admin.firestore.Timestamp.now(),
                    platformFee, netEarnings, releasedBy: userId, commissionRate
                },
                'platformFee': admin.firestore.FieldValue.increment(platformFee),
                'netEarnings': admin.firestore.FieldValue.increment(netEarnings),
                'escrowBalance': admin.firestore.FieldValue.increment(-amount)
            });

            const workerRef = db.collection("users").doc(workerId);
            transaction.update(workerRef, {
                "walletBalance": admin.firestore.FieldValue.increment(netEarnings)
            });

            const transactionRef = db.collection("transactions").doc();
            transaction.set(transactionRef, {
                id: transactionRef.id,
                projectId, userId: workerId, payerId: userId,
                amount, platformFee, netEarnings, commissionRate,
                type: 'milestone_payment',
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        // NOTIFICATION: Payment Released
        if (workerId) {
            await sendNotification(
                workerId,
                "Payment Released! 💸",
                `The client has released ₹${amount} to your wallet. Great work!`,
                { projectId, amount: amount.toString() },
                "payment_released"
            );
        }

        res.json({ success: true, message: "Payment released successfully" });

    } catch (error) {
        console.error("Release Payment Error:", error.message);
        const code = error.message.includes("found") ? 404 : 400; // Simplified status mapping
        res.status(code).json({ success: false, message: error.message });
    }
};
