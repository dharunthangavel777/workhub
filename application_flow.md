# WORK HUB APPLICATION FLOW

## WORKER MODEL
### 1. Onboarding & Auth
- **Sign up/Login**: UnifiedLoginScreen.
- **Guest Mode**: Available for browsing (Home only).
- **Personalized Access**: Prompt displayed when accessing protected tabs.

### 2. Navigation (Bottom Bar)
- **Home**: `JobSearchDashboardScreen`
  - AI Match Button
  - Search & Filter Jobs
- **Projects/Jobs**: `WorkerProjectsScreen`
  - Tracks Applied and Active projects.
- **Reels**: `ReelsTabContainer`
  - Short video feed for gig discovery.
- **Profile**: `ProfileScreen`
  - Manage Portfolio, Skills, Settings.

### 3. Key Actions
- Apply for Jobs & Projects.
- Chat with Clients (`ChatProvider`).
- Manage Contracts & Milestones.
- View Earnings & Withdraw Funds.

## BUSINESS OWNER MODEL
### 1. Onboarding & Auth
- Secure Sign up/Login.
- Profile setup for Company/Individual.

### 2. Navigation (Bottom Bar)
- **Home**: `OwnerHome`
  - Dashboard overview, quick stats.
- **Jobs**: `ManageJobsScreen`
  - List of Posted Jobs/Projects.
  - "Post New Job/Project" functionality.
- **Profile**: `ProfileScreen`
  - Manage Company settings.

### 3. Key Actions
- Post Jobs and Projects.
- Review Applicants (Resumes, Proposals).
- Initiate Contracts.
- Manage Escrow & Release Payments.

## EXECUTIVE ADMIN MODEL (Web Console)
### 1. Dashboard
- **Executive Overview**: Real-time metrics (Users, Active Opportunities, Revenue).
- **AI Strategy Assistant**: Insight generation.
- **Recent Activity Log**: Audit trail.

### 2. User Ecosystem
- **Workers**: List usage, view verification status, suspend/activate.
- **Business Owners**: List usage, verify companies.
- **Verification**: Dedicated queue for user verification.

### 3. Moderation
- **Job Posts**: Review and approve/reject content.
- **Projects**: Review and approve/reject.
- **Pending Review**: Centralized queue for approvals.

### 4. Finance & Trust
- **Finance & Revenue**: Monitor platform commission.
- **Withdrawals**: Process user withdrawal requests.
- **Disputes**: Resolve conflicts between Workers and Owners.

### 5. System
- **Carousel**: Manage promotional banners.
- **Settings**: Platform configuration.
