require('dotenv').config();

function getCashfreeConfig() {
    const appId = process.env.CASHFREE_APP_ID;
    const secretKey = process.env.CASHFREE_SECRET_KEY;
    const apiVersion = process.env.CASHFREE_API_VERSION || "2022-09-01";
    const mode = process.env.CASHFREE_MODE || "sandbox";

    if (!appId || !secretKey) {
        throw new Error("Payment gateway not configured. Missing CASHFREE_APP_ID or CASHFREE_SECRET_KEY.");
    }

    const isSandbox = mode !== "production";
    const baseUrl = isSandbox
        ? "https://sandbox.cashfree.com/pg"
        : "https://api.cashfree.com/pg";

    return { appId, secretKey, apiVersion, baseUrl, isSandbox };
}

module.exports = { getCashfreeConfig };
