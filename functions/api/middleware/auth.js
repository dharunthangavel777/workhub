const admin = require('firebase-admin');

// Middleware to verify Firebase ID Token
const verifyAuth = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            success: false,
            error: 'Unauthorized',
            message: 'No token provided'
        });
    }

    const idToken = authHeader.split('Bearer ')[1];

    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        req.user = decodedToken; // Attach decoded token to request
        req.uid = decodedToken.uid; // Convenience
        next();
    } catch (error) {
        console.error('Error verifying auth token:', error);
        return res.status(403).json({
            success: false,
            error: 'Forbidden',
            message: 'Invalid or expired token',
            details: error.message
        });
    }
};

module.exports = verifyAuth;
