const express = require('express');
const router = express.Router();
const projectController = require('../controllers/projectController');
const verifyAuth = require('../middleware/auth');

router.post('/approveBid', verifyAuth, projectController.approveBid);

module.exports = router;
