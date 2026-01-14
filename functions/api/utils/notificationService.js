const { admin, db } = require('../config/firebase');

/**
 * Reusable Helper to Send Push Notifications
 */
async function sendNotification(recipientId, title, body, data = {}, category = 'system') {
    try {
        if (!recipientId) return;

        const userDoc = await db.collection('users').doc(recipientId).get();
        if (!userDoc.exists) {
            console.log(`Notification skipped: User ${recipientId} not found`);
            return;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        // 1. Audit Log (Always save to Firestore)
        await db.collection('notifications').add({
            recipientId,
            title,
            body,
            data,
            category,
            status: fcmToken ? 'sent' : 'pending_token',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false
        });

        // 2. Send Push if Token Exists
        if (fcmToken) {
            const message = {
                token: fcmToken,
                notification: { title, body },
                data: {
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    category,
                    ...data,
                },
                android: {
                    priority: 'high',
                    notification: { channelId: 'high_importance_channel' }
                },
                apns: {
                    payload: { aps: { sound: 'default', contentAvailable: true } }
                }
            };
            await admin.messaging().send(message);
            console.log(`Notification sent to ${recipientId}: ${title}`);
        }
    } catch (error) {
        console.error("Send Notification Helper Error:", error);
    }
}

module.exports = { sendNotification };
