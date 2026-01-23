import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:work_hub/theme/custom_colors.dart';
import 'package:work_hub/logic/providers/auth_provider.dart';
import 'package:work_hub/logic/providers/job_provider.dart';
import 'package:work_hub/data/services/payment_service.dart';

class SubscriptionSelectionScreen extends StatelessWidget {
  const SubscriptionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final isOwner = user?.role.name == 'businessOwner';

    final plans = isOwner ? _ownerPlans : _workerPlans;

    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(
        title: const Text("Choose Your Plan"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: CustomColors.darkGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (user != null && user.isTrialActive) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.2),
                          Colors.orange.withValues(alpha: 0.2)
                        ],
                      ),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(FontAwesomeIcons.crown,
                            color: Colors.amber, size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          "Welcome to your 14-Day Free Trial!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You have full access to Pro features until ${user.trialStartDate != null ? DateTime.fromMillisecondsSinceEpoch(user.trialStartDate!.millisecondsSinceEpoch + (14 * 24 * 60 * 60 * 1000)).toString().split(' ')[0] : 'the end of your trial'}.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: CustomColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
                const Text(
                  "Elevate Your Experience",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CustomColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Choose a plan that fits your professional needs.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CustomColors.textMuted),
                ),
                const SizedBox(height: 32),
                ...plans.map(
                  (plan) => _PlanCard(
                    plan: plan,
                    isCurrent: user?.subscriptionTier == plan.title,
                    onSelect: () => _handlePlanSelection(context, plan.title),
                  ),
                ),
                if (user != null &&
                    !user.hasSeenSubscription &&
                    user.isTrialActive) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthProvider>().markSubscriptionAsSeen();
                        // RootWrapper will automatically handle navigation
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Continue to Dashboard"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePlanSelection(BuildContext context, String tier) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    if (user != null) {
      if (tier == 'Starter' || tier == 'Basic') {
        // Free plans don't need payment
        _completeSubscription(context, tier, user.uid);
        return;
      }

      // Start Payment Flow
      final paymentService = PaymentService();
      final double amount =
          tier == 'Pro' ? 49.0 : 15.0; // Simplified amount logic
      final String orderId =
          'SUB_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      final sessionId = await paymentService.createOrder(
        orderId: orderId,
        amount: amount,
        customerId: user.uid,
        customerPhone: '9999999999', // Phone not in UserModel yet
        customerEmail: user.email,
      );

      if (context.mounted) Navigator.pop(context); // Close loading

      if (sessionId != null) {
        paymentService.startMobilePayment(
          sessionId,
          orderId,
          (verifiedOrderId) async {
            // Verify payment on server
            final isPaid = await paymentService.verifyPayment(verifiedOrderId);
            if (isPaid && context.mounted) {
              _completeSubscription(context, tier, user.uid);
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Payment verification failed.")),
              );
            }
          },
          (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment failed: $error")),
              );
            }
          },
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Failed to create payment order. Check console.")),
          );
        }
      }
    }
  }

  Future<void> _completeSubscription(
    BuildContext context,
    String tier,
    String userId,
  ) async {
    final jobProvider = context.read<JobProvider>();

    await jobProvider.updateUserProfile(userId, {
      'subscriptionTier': tier,
      'subscriptionExpiry':
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
      'hasSeenSubscription': true,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully upgraded to $tier!")),
      );
      // Wait a bit for the UI to update or just pop
      Navigator.pop(context);
    }
  }

  static final List<_PlanData> _ownerPlans = [
    _PlanData(
      title: "Starter",
      price: "Free",
      features: [
        "Basic job posts",
        "5 applicants per post",
        "Standard support",
      ],
      icon: FontAwesomeIcons.seedling,
      color: Colors.green,
    ),
    _PlanData(
      title: "Pro",
      price: "₹49/mo",
      features: [
        "Unlimited applicants",
        "Featured job badges",
        "Advanced filtering",
      ],
      icon: FontAwesomeIcons.rocket,
      color: CustomColors.primaryBlue,
    ),
    _PlanData(
      title: "Enterprise",
      price: "Custom",
      features: ["Dedicated manager", "Multiple hiring seats", "API Access"],
      icon: FontAwesomeIcons.building,
      color: Colors.purple,
    ),
  ];

  static final List<_PlanData> _workerPlans = [
    _PlanData(
      title: "Basic",
      price: "Free",
      features: ["10 bids per month", "Standard profile", "Email support"],
      icon: FontAwesomeIcons.user,
      color: Colors.grey,
    ),
    _PlanData(
      title: "Elite",
      price: "₹15/mo",
      features: ["Unlimited bids", "Verified Pro badge", "Priority placement"],
      icon: FontAwesomeIcons.crown,
      color: Colors.amber,
    ),
  ];
}

class _PlanData {
  final String title;
  final String price;
  final List<String> features;
  final IconData icon;
  final Color color;

  _PlanData({
    required this.title,
    required this.price,
    required this.features,
    required this.icon,
    required this.color,
  });
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: CustomColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? plan.color : Colors.black.withValues(alpha: 0.05),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: plan.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(plan.icon, color: plan.color, size: 24),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: plan.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Current Plan",
                      style: TextStyle(
                        color: plan.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: CustomColors.darkText,
              ),
            ),
            Text(
              plan.price,
              style: TextStyle(
                fontSize: 18,
                color: plan.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.black12),
            const SizedBox(height: 24),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: plan.color,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      f,
                      style: const TextStyle(color: CustomColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isCurrent ? null : onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.color,
                  disabledBackgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isCurrent ? "Active Plan" : "Upgrade Now",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
