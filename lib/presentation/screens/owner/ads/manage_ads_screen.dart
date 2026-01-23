import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_hub/config/app_export.dart';
import 'package:work_hub/logic/providers/ad_provider.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/theme/text_style_helper.dart';
import 'package:work_hub/theme/theme_helper.dart';
import 'package:work_hub/presentation/screens/owner/ads/create_ad_screen.dart';

class ManageAdsScreen extends StatefulWidget {
  const ManageAdsScreen({super.key});

  @override
  State<ManageAdsScreen> createState() => _ManageAdsScreenState();
}

class _ManageAdsScreenState extends State<ManageAdsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userModel != null) {
        context.read<AdProvider>().fetchOwnerAds(auth.userModel!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adProvider = context.watch<AdProvider>();
    final ads = adProvider.ownerAds;

    return Scaffold(
      backgroundColor: appTheme.white_A700,
      appBar: AppBar(
        title: Text("Manage Campaigns",
            style: TextStyleHelper.instance.headline22Bold),
        centerTitle: true,
        backgroundColor: appTheme.white_A700,
        elevation: 0,
        iconTheme: IconThemeData(color: appTheme.indigo_A700),
      ),
      body: adProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(color: appTheme.indigo_A700))
          : ads.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: ads.length,
                  padding: EdgeInsets.all(16.h),
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.h)),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(12.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            Container(
                              width: 80.h,
                              height: 120.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.h),
                                image: DecorationImage(
                                  image: NetworkImage(ad.thumbnailUrl.isNotEmpty
                                      ? ad.thumbnailUrl
                                      : "https://via.placeholder.com/80x120"),
                                  fit: BoxFit.cover,
                                ),
                                color: appTheme.gray_200,
                              ),
                            ),
                            SizedBox(width: 12.w),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ad.caption,
                                          style: TextStyleHelper
                                              .instance.body14Bold,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _buildStatusBadge(ad.status),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Icon(Icons.remove_red_eye,
                                          size: 14.h, color: appTheme.gray_500),
                                      SizedBox(width: 4.w),
                                      Text("${ad.views} Views",
                                          style: TextStyleHelper
                                              .instance.body12Medium),
                                      SizedBox(width: 12.w),
                                      Icon(Icons.touch_app,
                                          size: 14.h, color: appTheme.gray_500),
                                      SizedBox(width: 4.w),
                                      Text("${ad.clicks} Clicks",
                                          style: TextStyleHelper
                                              .instance.body12Medium),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Budget: ₹${ad.remainingBudget.toStringAsFixed(0)} / ₹${ad.totalBudget.toStringAsFixed(0)}",
                                    style: TextStyleHelper.instance.body12Medium
                                        .copyWith(color: appTheme.indigo_A700),
                                  ),
                                  if (ad.status == 'rejected' &&
                                      ad.rejectionReason != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8.h),
                                      child: Text(
                                        "Reason: ${ad.rejectionReason}",
                                        style: TextStyleHelper
                                            .instance.body12Medium
                                            .copyWith(color: Colors.red),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreateAdScreen()));
        },
        backgroundColor: appTheme.indigo_A700,
        icon: const Icon(Icons.add),
        label: const Text("Create Campaign"),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64.h, color: appTheme.gray_300),
          SizedBox(height: 16.h),
          Text("No Campaigns Yet",
              style: TextStyleHelper.instance.body14Medium
                  .copyWith(color: appTheme.gray_500)),
          SizedBox(height: 8.h),
          Text("Create your first ad campaign to reach workers.",
              style: TextStyleHelper.instance.body14Medium),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = appTheme.gray_500;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyleHelper.instance.body10Medium.copyWith(color: color),
      ),
    );
  }
}
