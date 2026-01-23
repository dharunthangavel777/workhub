import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import 'package:work_hub/theme/theme_helper.dart';
import 'package:work_hub/utils/size_utils.dart';

import '../../../config/app_export.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/data/models/user_model.dart';
import '../settings/become_owner_screen.dart';
import '../owner/subscription_selection_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = "1.1.0";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint("Error loading package info: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: appTheme.white_A700_01,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyleHelper.instance.headline22Bold
              .copyWith(color: appTheme.gray_900),
        ),
        backgroundColor: appTheme.white_A700_01,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: appTheme.gray_900),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        children: [
          _buildSectionHeader("Account"),
          SizedBox(height: 16.h),
          _buildSettingTile(
            context,
            icon: Icons.person_outline,
            title: "Edit Profile",
            subtitle: "Update your name, bio, and location",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.verified_user_outlined,
            title: "Verification Status",
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: (user?.isVerified ?? false)
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.h),
              ),
              child: Text(
                (user?.isVerified ?? false) ? "VERIFIED" : "PENDING",
                style: TextStyleHelper.instance.body10Bold.copyWith(
                  color: (user?.isVerified ?? false)
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          ),
          if (user?.role == UserRole.worker)
            _buildSettingTile(
              context,
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
              context,
              icon: Icons.card_membership_outlined,
              title: "Subscription",
              subtitle: (user?.isTrialActive ?? false)
                  ? "Free Trial Active"
                  : "${user?.subscriptionTier ?? 'Free'} Plan",
              trailing: (user?.isTrialActive ?? false)
                  ? Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: appTheme.indigo_A700.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.h),
                      ),
                      child: Text(
                        "TRIAL",
                        style: TextStyleHelper.instance.body10Bold
                            .copyWith(color: appTheme.indigo_A700),
                      ),
                    )
                  : Icon(Icons.chevron_right, color: appTheme.gray_400),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SubscriptionSelectionScreen()),
              ),
            ),
          SizedBox(height: 32.h),
          _buildSectionHeader("Preferences"),
          SizedBox(height: 16.h),
          _buildSettingTile(
            context,
            icon: Icons.notifications_none,
            title: "Notifications",
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.lock_outline,
            title: "Privacy & Security",
            onTap: () {},
          ),
          SizedBox(height: 32.h),
          _buildSectionHeader("Support"),
          SizedBox(height: 16.h),
          _buildSettingTile(
            context,
            icon: Icons.help_outline,
            title: "Help Center",
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: "About Work Hub",
            onTap: () {},
          ),
          SizedBox(height: 48.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton.icon(
              onPressed: () => _showSignOutDialog(context, auth),
              icon: Icon(Icons.logout, color: Colors.white, size: 20.h),
              label: Text("Sign Out",
                  style: TextStyleHelper.instance.body16Bold
                      .copyWith(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.gray_900,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.h)),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Center(
            child: Text(
              "Version $_appVersion",
              style: TextStyleHelper.instance.body12Medium
                  .copyWith(color: appTheme.gray_400),
            ),
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyleHelper.instance.body14Bold
          .copyWith(color: appTheme.indigo_A700),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700_01,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.gray_100),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          padding: EdgeInsets.all(8.h),
          decoration: BoxDecoration(
            color: appTheme.gray_50,
            borderRadius: BorderRadius.circular(10.h),
          ),
          child: Icon(icon, color: appTheme.gray_900, size: 20.h),
        ),
        title: Text(
          title,
          style: TextStyleHelper.instance.body14Bold
              .copyWith(color: appTheme.gray_900),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyleHelper.instance.body12Medium
                    .copyWith(color: appTheme.gray_500),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right,
                    color: appTheme.gray_400, size: 20.h)
                : null),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appTheme.white_A700_01,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
        title: Text("Sign Out", style: TextStyleHelper.instance.body18Bold),
        content: Text("Are you sure you want to sign out?",
            style: TextStyleHelper.instance.body14Medium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: appTheme.gray_500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text("Sign Out",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
