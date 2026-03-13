import 'package:provider/provider.dart';
import 'package:work_hub/core/config/app_export.dart';
import 'package:work_hub/features/auth/logic/auth_controller.dart';
import 'package:work_hub/core/services/toast_service.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

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
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Privacy & Security',
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                  children: [
                    _buildSectionHeader("Identity Verification"),
                    SizedBox(height: 16.h),
                    _buildInfoTile(
                      context,
                      icon: Icons.verified_user_outlined,
                      title: "Verification Status",
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: (user?.isVerified ?? false)
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
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
                    Padding(
                      padding: EdgeInsets.only(top: 8.h, left: 4.w, right: 4.w),
                      child: Text(
                        "Verification helps us maintain a safe community. Verified users get a badge on their profile and higher trust from clients/workers.",
                        style: TextStyleHelper.instance.body12Medium
                            .copyWith(color: appTheme.gray_600),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    _buildSectionHeader("Account Security"),
                    SizedBox(height: 16.h),
                    _buildActionTile(
                      context,
                      icon: Icons.password_outlined,
                      title: "Change Password",
                      onTap: () {
                        ToastService().showInfo("Reset Email Sent", 
                          message: "Password reset email sent (Demo)");
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.phonelink_lock_outlined,
                      title: "Two-Factor Authentication",
                      trailing: Switch(
                        value: false,
                        onChanged: (v) {},
                        activeTrackColor: appTheme.indigo_A700.withValues(alpha: 0.5),
                        activeColor: appTheme.indigo_A700,
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

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget trailing,
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
        trailing: trailing,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
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
        trailing: trailing ??
            Icon(Icons.chevron_right, color: appTheme.gray_400, size: 20.h),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
      ),
    );
  }
}