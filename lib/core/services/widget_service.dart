import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_widget/home_widget.dart';
import 'package:work_hub/features/auth/models/user.dart';

class WidgetService {
  static const String appGroupId = 'group.work_hub';
  static const String androidWidgetName = 'DashboardWidgetProvider';

  static Future<void> updateDashboardWidget([UserModel? user]) async {
    try {
      final firestore = FirebaseFirestore.instance;

      UserModel? currentUser = user;

      if (currentUser == null) {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser == null) return;

        final userDoc =
            await firestore.collection('users').doc(authUser.uid).get();
        if (!userDoc.exists) return;
        currentUser = UserModel.fromMap(userDoc.data()!);
      }

      // 1. MOCKED Post Counts
      const String jobCount = "20+";
      const String freelanceCount = "10";

      // 2. MOCKED Active Project Progress
      String projectTitle = "Mobile App Development";
      int projectProgress = 67;

      // 3. Save Widget Data
      await HomeWidget.saveWidgetData<String>(
          'userName', currentUser.displayName.split(' ')[0]);
      await HomeWidget.saveWidgetData<String>('jobCount', jobCount.toString());
      await HomeWidget.saveWidgetData<String>(
          'freelanceCount', freelanceCount.toString());
      await HomeWidget.saveWidgetData<String>('projectTitle', projectTitle);
      await HomeWidget.saveWidgetData<int>('projectProgress', projectProgress);

      // 4. Update the widget
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        qualifiedAndroidName: 'com.workhub.work_hub.DashboardWidgetProvider',
      );
      print("Widget Updated with New Layout Successfully");
    } catch (e) {
      print("Error updating widget: $e");
    }
  }
}



