const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Config
require('./config/firebase'); // Initializes Firebase Admin

// Routes
const userRoutes = require('./routes/userRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const projectRoutes = require('./routes/projectRoutes');
// Utility for direct notification
const { sendNotification } = require('./utils/notificationService');
const verifyAuth = require('./middleware/auth');

const app = express();

// Middleware
app.use(cors({ origin: true }));
app.use(express.json());

// Helper Route for Notifications (Direct API)
app.post('/sendPushNotification', verifyAuth, async (req, res) => {
    try {
        const { recipientId, title, body, data } = req.body;

        if (!recipientId || !title || !body) {
            return res.status(400).json({ success: false, message: "Missing required fields" });
        }

        // Reuse helper
        const category = (data && data.category) ? data.category : 'manual';
        await sendNotification(recipientId, title, body, data, category);

        res.json({ success: true });

    } catch (error) {
        console.error("Send Notification Error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Mount Routes
// Note: The previous monolithic app mounted routes at root (e.g. /initializeUser)
// We must preserve these paths for the Flutter app to work without changes.
app.use('/', userRoutes);
app.use('/', paymentRoutes);
app.use('/', projectRoutes);

/**
 * Health Check
 */
app.get('/', (req, res) => {
    res.json({
        message: 'Work Hub Backend is Running (Refactored)',
        config: {
            firebase: !!process.env.FIREBASE_SERVICE_ACCOUNT,
            cashfreeId: !!process.env.CASHFREE_APP_ID,
            cashfreeSecret: !!process.env.CASHFREE_SECRET_KEY,
            mode: process.env.CASHFREE_MODE || 'sandbox'
        }
    });
});

// Start Server (If running directly)
const PORT = process.env.PORT || 3000;
if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}

module.exports = app;
