const { admin, db } = require('../config/firebase');
const { sendNotification } = require('../utils/notificationService');

exports.approveBid = async (req, res) => {
    try {
        const { postId, workerId, workerName, title, description, mode, bidAmount } = req.body;
        const userId = req.uid;

        if (!postId || !workerId || !title) return res.status(400).json({ success: false, message: "Missing required fields" });

        const collection = mode === 'freelancer' ? 'project_posts' : 'job_posts';

        const result = await db.runTransaction(async (transaction) => {
            const postRef = db.collection(collection).doc(postId);
            const postDoc = await transaction.get(postRef);

            if (!postDoc.exists) throw new Error("Post not found");
            if (postDoc.data().ownerId !== userId) throw new Error("Only the owner can approve bids");
            if (postDoc.data().status === 'filled') throw new Error("Post already filled");

            transaction.update(postRef, {
                [`applicants.${workerId}.status`]: 'approved',
                'status': 'filled'
            });

            const workerAppRef = db.collection("users").doc(workerId).collection("applications").doc(postId);
            transaction.update(workerAppRef, { 'status': 'approved' });

            const projectRef = db.collection("projects").doc();
            transaction.set(projectRef, {
                id: projectRef.id,
                postId, ownerId: userId, workerId, workerName: workerName || 'Worker',
                title, description, mode: mode || 'job',
                budget: bidAmount || 0,
                escrowBalance: 0, status: 'ongoing', progress: 0.0,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return projectRef.id;
        });

        // NOTIFICATION: Bid Approved
        await sendNotification(
            workerId,
            "Application Accepted! 🎉",
            `Your application for '${title}' has been accepted. View the project to start setup.`,
            { postId: postId, projectId: result },
            "bid_approved"
        );

        res.json({ success: true, projectId: result });

    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
