import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../logic/providers/auth_provider.dart';

import '../../../data/models/user_model.dart';
import '../settings/become_owner_screen.dart';
import '../owner/subscription_selection_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Account",
            style: TextStyle(
              color: CustomColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.person_outline,
            title: "Edit Profile",
            subtitle: "Update your name, bio, and location",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _buildSettingTile(
            icon: Icons.verified_user_outlined,
            title: "Verification Status",
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (user?.isVerified ?? false)
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (user?.isVerified ?? false) ? "VERIFIED" : "PENDING",
                style: TextStyle(
                  color: (user?.isVerified ?? false)
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (user?.role == UserRole.worker)
            _buildSettingTile(
              icon: Icons.business_center_outlined,
              title: "Become a Business Owner",
              subtitle: user?.ownerRequestStatus == 'pending'
                  ? "Request Pending Review"
                  : "Post jobs and hire talent",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BecomeOwnerScreen()),
              ),
            ),
          if (user?.role == UserRole.businessOwner)
            _buildSettingTile(
              icon: Icons.card_membership_outlined,
              title: "Subscription",
              subtitle: (user?.isTrialActive ?? false)
                  ? "Free Trial Active"
                  : "${user?.subscriptionTier ?? 'Free'} Plan",
              trailing: (user?.isTrialActive ?? false)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CustomColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "TRIAL",
                        style: TextStyle(
                          color: CustomColors.primaryBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SubscriptionSelectionScreen()),
              ),
            ),
          const SizedBox(height: 32),
          const Text(
            "Preferences",
            style: TextStyle(
              color: CustomColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.notifications_none,
            title: "Notifications",
            onTap: () {},
          ),
          const SizedBox(height: 32),
          const Text(
            "Support",
            style: TextStyle(
              color: CustomColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: "Help Center",
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: "About Work Hub",
            onTap: () {},
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _showSignOutDialog(context, auth),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: CustomColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CustomColors.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: CustomColors.darkText),
        title: Text(
          title,
          style: const TextStyle(color: CustomColors.darkText, fontSize: 14),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: CustomColors.textMuted,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: CustomColors.textMuted)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await auth.signOut();
              if (context.mounted) {
                // Clear navigation stack and return to root (Login/Onboarding)
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
