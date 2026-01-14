const { admin, db } = require('../config/firebase');
const { sendNotification } = require('../utils/notificationService');

exports.initializeUser = async (req, res) => {
    try {
        const userId = req.uid;
        const userRef = db.collection("users").doc(userId);

        const doc = await userRef.get();
        if (doc.exists && doc.data().createdAt) {
            return res.json({ success: true, message: "User already initialized" });
        }

        await userRef.set({
            role: 'worker',          // Default all new users to worker
            isVerified: true,        // Basic verification for OAuth users
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            walletBalance: 0,        // Prevent initialization with funds
            ownerRequestStatus: 'none',
            isTrialActive: false,
            hasSeenSubscription: false,
            activeMode: 'job',
            subscriptionTier: 'Free'
        }, { merge: true });

        // WELCOME NOTIFICATION
        await sendNotification(
            userId,
            "Welcome to Work Hub! 🚀",
            "We're excited to have you on board. Complete your profile to get started.",
            {},
            "account_welcome"
        );

        res.json({ success: true, message: "User initialized successfully" });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.requestWithdrawal = async (req, res) => {
    try {
        const { amount: rawAmount } = req.body;
        const amount = parseFloat(rawAmount);
        const userId = req.uid;

        if (!amount || amount <= 0) return res.status(400).json({ success: false, message: "Invalid amount" });

        const userRef = db.collection("users").doc(userId);

        await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) throw new Error("User not found");

            const userData = userDoc.data();
            const currentBalance = userData.walletBalance || 0;
            const settingsDoc = await transaction.get(db.collection("platform_settings").doc("revenue"));
            const minWithdrawal = settingsDoc.exists ? (settingsDoc.data().minWithdrawal || 50) : 50;

            if (amount < minWithdrawal) throw new Error(`Minimum withdrawal is $${minWithdrawal}`);
            if (amount > currentBalance) throw new Error("Insufficient wallet balance");

            transaction.update(userRef, {
                "walletBalance": admin.firestore.FieldValue.increment(-amount),
                "pendingWithdrawal": admin.firestore.FieldValue.increment(amount)
            });

            const requestRef = db.collection("withdrawal_requests").doc();
            transaction.set(requestRef, {
                id: requestRef.id,
                userId: userId,
                amount: amount,
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        // NOTIFICATION: Withdrawal Requested
        await sendNotification(
            userId,
            "Withdrawal Pending",
            `Your request for ₹${amount} has been received and is being processed.`,
            {},
            "withdrawal_pending"
        );

        res.json({ success: true, message: "Withdrawal request submitted" });

    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
