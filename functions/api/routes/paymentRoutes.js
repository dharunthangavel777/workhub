const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const verifyAuth = require('../middleware/auth');

router.post('/createPaymentOrder', verifyAuth, paymentController.createPaymentOrder);
router.post('/verifyPaymentStatus', verifyAuth, paymentController.verifyPaymentStatus);
router.post('/releasePayment', verifyAuth, paymentController.releasePayment);

module.exports = router;
