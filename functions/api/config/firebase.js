const admin = require('firebase-admin');
require('dotenv').config();

// Initialize Firebase Admin
// Expects GOOGLE_APPLICATION_CREDENTIALS or setup via service account key
if (!admin.apps.length) {
    try {
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
        } else {
            console.log("No FIREBASE_SERVICE_ACCOUNT, using default");
            admin.initializeApp();
        }
    } catch (e) {
        console.error("Firebase Admin Initialization Error:", e);
    }
}

const db = admin.firestore();

module.exports = { admin, db };
