import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';

import 'become_owner_screen.dart';
import 'privacy_security_screen.dart';
import 'help_center_screen.dart';
import 'about_us_screen.dart';

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
      backgroundColor: CustomColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// HEADER WITH BACK BUTTON
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Settings',
                    style: TextStyleHelper.instance.headline22Bold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            /// WHITE BODY
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: appTheme.white_A700_01,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.h),
                    topRight: Radius.circular(32.h),
                  ),
                ),
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                  children: [
                    _buildSectionHeader("Account"),
                    SizedBox(height: 16.h),
                    _buildSettingTile(
                      context,
                      icon: Icons.business_center_outlined,
                      title: "Become a Business Owner",
                      subtitle:
                          _getOwnerStatusSubtitle(user?.ownerRequestStatus),
                      trailing:
                          _buildOwnerStatusBadge(user?.ownerRequestStatus),
                      onTap: (user?.ownerRequestStatus == 'none' ||
                              user?.ownerRequestStatus == 'rejected')
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const BecomeOwnerScreen()),
                              )
                          : null,
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrivacySecurityScreen()),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    _buildSectionHeader("Support"),
                    SizedBox(height: 16.h),
                    _buildSettingTile(
                      context,
                      icon: Icons.help_outline,
                      title: "Help Center",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpCenterScreen()),
                      ),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.info_outline,
                      title: "About Work Hub",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AboutUsScreen()),
                      ),
                    ),
                    SizedBox(height: 48.h),

                    /// SIGN OUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSignOutDialog(context, auth),
                        icon: Icon(Icons.logout, color: Colors.red, size: 20.h),
                        label: Text("Sign Out",
                            style: TextStyleHelper.instance.body16Bold
                                .copyWith(color: Colors.red)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.h),
                              side: BorderSide(
                                  color: Colors.red.withOpacity(0.2))),
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
              ),
            ),
          ],
        ),
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

  String _getOwnerStatusSubtitle(String? status) {
    switch (status) {
      case 'pending':
        return "Request is under review";
      case 'approved':
        return "Your request was approved!";
      case 'rejected':
        return "Request rejected. Tap to try again.";
      default:
        return "Start hiring for your company";
    }
  }

  Widget _buildOwnerStatusBadge(String? status) {
    if (status == null || status == 'none') return const SizedBox.shrink();

    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = "PENDING";
        break;
      case 'approved':
        color = Colors.green;
        text = "APPROVED";
        break;
      case 'rejected':
        color = Colors.red;
        text = "REJECTED";
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Text(
        text,
        style: TextStyleHelper.instance.body10Bold.copyWith(
          color: color,
        ),
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
            child: const Text("Sign Out",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
