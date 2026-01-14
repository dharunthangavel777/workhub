const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const verifyAuth = require('../middleware/auth');

router.post('/initializeUser', verifyAuth, userController.initializeUser);
router.post('/requestWithdrawal', verifyAuth, userController.requestWithdrawal);

module.exports = router;
