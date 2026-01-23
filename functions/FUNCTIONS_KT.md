# Work Hub Backend Functions - Knowledge Transfer (KT) Document

## 1. Overview
The `functions` directory contains the backend logic for the Work Hub application. It is built as a **monolithic Node.js/Express application** designed to be hosted on Vercel or similar serverless platforms (though currently structured as a standard Express app). It handles critical business logic that requires security and trusted environment execution, such as payments, withdrawals, and sensitive database updates.

## 2. File Structure
```
functions/
├── package.json          # Dependencies and scripts
├── .env                  # Environment variables (Keys, Secrets)
├── api/
│   ├── index.js          # App Entry Point, Middleware, Route Mounting
│   ├── config/
│   │   ├── firebase.js   # Firebase Admin SDK Initialization
│   │   └── cashfree.js   # Cashfree Payment Gateway Config
│   ├── routes/           # API Route Definitions
│   │   ├── userRoutes.js
│   │   ├── paymentRoutes.js
│   │   └── projectRoutes.js
│   ├── controllers/      # Business Logic & Request Handlers
│   │   ├── userController.js
│   │   ├── paymentController.js
│   │   └── projectController.js
│   ├── middleware/
│   │   └── auth.js       # Firebase ID Token Verification
│   └── utils/
│       └── notificationService.js # FCM Push Notification Helper
```

## 3. Tech Stack
-   **Runtime**: Node.js (>=16)
-   **Framework**: Express.js (v4.18)
-   **Database**: Cloud Firestore (via `firebase-admin`)
-   **Authentication**: Firebase Authentication (ID Token verification)
-   **Payments**: Cashfree Payment Gateway (via `axios` REST calls)
-   **Notifications**: Firebase Cloud Messaging (FCM)
-   **Deployment**: Vercel (Configured via `vercel.json` - inferred)

## 4. Technical Description
The backend exposes a REST API consumed by the Flutter mobile application.
-   **Security**: All protected routes use the `verifyAuth` middleware, which validates the Firebase ID Token sent in the `Authorization` header (`Bearer <token>`).
-   **Data Integrity**: Uses Firestore Transactions for sensitive operations like wallet balances and project status updates to prevent race conditions.
-   **Notifications**: Integrated `notificationService` automatically sends Push Notifications via FCM when business events occur (e.g., bid accepted, money received).

## 5. Code Explanation (Step-by-Step)

### A. Entry Point (`api/index.js`)
-   **Setup**: Initializes Express, CORS, and `dotenv`.
-   **Config**: Connects to Firebase Admin.
-   **Middleware**: Uses `cors` and `express.json()`.
-   **Direct Route**: `/sendPushNotification` allows triggering notifications manually (protected by auth).
-   **Route Mounting**:
    -   `userRoutes`, `paymentRoutes`, and `projectRoutes` are all mounted at root `/`.
-   **Health Check**: Root `GET /` returns server status and config checks.

### B. Middleware (`api/middleware/auth.js`)
-   **`verifyAuth`**:
    1.  Checks for `Authorization: Bearer <token>` header.
    2.  Uses `admin.auth().verifyIdToken(idToken)` to decode/validate.
    3.  Attaches `req.user` and `req.uid` to the request object.
    4.  Calls `next()` or returns 401/403 on failure.

### C. User Module (`userRoutes.js` -> `userController.js`)
1.  **`initializeUser` (POST /initializeUser)**
    -   Checks if user exists in Firestore.
    -   If not, creates the user document with default fields (`role: worker`, `walletBalance: 0`, etc.).
    -   Sends a "Welcome" notification.
2.  **`requestWithdrawal` (POST /requestWithdrawal)**
    -   Validates amount > minimum (50).
    -   **Transaction**:
        -   Checks user balance.
        -   Deducts amount from `walletBalance`.
        -   Adds amount to `pendingWithdrawal`.
        -   Creates a `withdrawal_requests` document.
    -   Sends "Withdrawal Pending" notification.

### D. Payment Module (`paymentRoutes.js` -> `paymentController.js`)
1.  **`createPaymentOrder` (POST /createPaymentOrder)**
    -   Validates inputs (Order ID, Amount, Customer details).
    -   Calls **Cashfree API** (`/orders`) to create a payment session.
    -   Saves order details to `payment_orders` collection (Audit Trail).
    -   Returns `payment_session_id` to Flutter app for SDK flow.
2.  **`verifyPaymentStatus` (POST /verifyPaymentStatus)**
    -   Called after payment completion on client.
    -   Calls **Cashfree API** (`/orders/:orderId`) to verify actual status.
    -   Updates `payment_orders` doc with `PAID` status.
    -   **Escrow Logic**: If `type === 'escrow_deposit'`, runs a transaction to check if already processed, then adds funds to `projects/{projectId}.escrowBalance`.
    -   Sends "Escrow Funded" notification to the worker.
3.  **`releasePayment` (POST /releasePayment)**
    -   **Transaction**:
        -   Verifies project owner and escrow balance.
        -   Calculates **Platform Fee** (defaults to 10%) and **Net Earnings**.
        -   Deducts from Project Escrow Balance.
        -   Adds `Net Earnings` to Worker's `walletBalance`.
        -   Records transaction in `transactions` collection.
    -   Sends "Payment Released" notification to worker.

### E. Project Module (`projectRoutes.js` -> `projectController.js`)
1.  **`approveBid` (POST /approveBid)**
    -   **Transaction**:
        -   Verifies Post ownership and availability.
        -   Updates Post status to `filled`.
        -   Updates Worker's application status to `approved`.
        -   Creates a **New Project** document (`projects/{newId}`) with `status: ongoing` and `escrowBalance: 0`.
    -   Sends "Application Accepted" notification to worker.

### F. Utils (`api/utils/notificationService.js`)
-   **`sendNotification`**:
    -   Looks up user's Firestore doc to get `fcmToken`.
    -   **Audit**: Writes notification payload to `notifications` collection.
    -   **Push**: Uses `admin.messaging().send()` to push to device.
