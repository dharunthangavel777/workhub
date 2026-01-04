import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import 'add_experience_screen.dart';
import 'add_portfolio_screen.dart';
import '../../../core/utils/image_utils.dart';
import '../../widgets/shared/custom_image_view.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId; // If null, show current user's profile

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCurrentUser = userId == null || userId == auth.userModel?.uid;

    // In a real app, we'd fetch the user by ID if it's not the current user.
    // For now, we'll assume it's the current user for simplicity in UI testing.
    final user = auth.userModel;

    if (auth.isLoading || user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isOwner = user.role == UserRole.businessOwner;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.black,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                actions: isCurrentUser
                    ? [
                        IconButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/settings'),
                          icon: const Icon(Icons.settings, color: Colors.white),
                        ),
                      ]
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: user.bannerImage == null
                          ? CustomColors.primaryGradient
                          : null,
                      image: user.bannerImage != null
                          ? DecorationImage(
                              image:
                                  ImageUtils.getImageProvider(user.bannerImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: isCurrentUser
                              ? () async {
                                  final picker = ImagePicker();
                                  final image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (image != null) {
                                    await auth
                                        .updateProfileImage(File(image.path));
                                  }
                                }
                              : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isCurrentUser &&
                                  !isOwner &&
                                  user.profileCompletion < 100)
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CircularProgressIndicator(
                                    value: user.profileCompletion / 100,
                                    strokeWidth: 4,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.3),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ),
                                ),
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    ImageUtils.getImageProvider(user.photoURL),
                                child: user.photoURL == null
                                    ? Text(
                                        (user.displayName).isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : "U",
                                        style: const TextStyle(
                                          color: CustomColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      )
                                    : null,
                              ),
                              if (isCurrentUser &&
                                  !isOwner &&
                                  user.profileCompletion < 100)
                                Positioned(
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CustomColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: Text(
                                      "${user.profileCompletion}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (isCurrentUser)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: CustomColors.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isOwner && user.companyName != null
                              ? user.companyName!
                              : user.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (user.jobCategory != null && !isOwner)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              user.jobCategory!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (isOwner && user.managerName != null)
                          Text(
                            "Manager: ${user.managerName}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          )
                        else if (user.username != null)
                          Text(
                            "@${user.username}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        if (user.location != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.location!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isOwner && user.companyWebsite != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.language,
                                  size: 14,
                                  color: CustomColors.primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.companyWebsite!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CustomColors.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrentUser &&
                          !isOwner &&
                          user.profileCompletion < 100) ...[
                        // Only showing a subtle alert text if not using the big block
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.orange.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Complete your profile to 100%!",
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Missing: ${user.missingProfileFields.join(', ')}",
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isCurrentUser) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final isFollowing = user.followers?.containsKey(
                                    auth.userModel?.uid,
                                  ) ??
                                  false;
                              if (isFollowing) {
                                auth.unfollowUser(userId!);
                              } else {
                                auth.followUser(userId!);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (user.followers
                                          ?.containsKey(auth.userModel?.uid) ??
                                      false)
                                  ? CustomColors.lightCard
                                  : CustomColors.primaryBlue,
                            ),
                            child: Text(
                              (user.followers
                                          ?.containsKey(auth.userModel?.uid) ??
                                      false)
                                  ? "Unfollow"
                                  : "Follow",
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (!isOwner && isCurrentUser) ...[
                        _ProfileSectionTitle(title: "Wallet & Earnings"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: CustomColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(FontAwesomeIcons.wallet,
                                  color: Colors.white, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Available Balance",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                    Text(
                                      "₹${user.walletBalance.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/withdrawal'),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: CustomColors.primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Withdraw",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (!isOwner) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: CustomColors.lightCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: CustomColors.primaryBlue
                                    .withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                  "Projects", "${user.completedProjects}"),
                              _buildVerticalDivider(),
                              _buildStatItem("Rating",
                                  "${user.rating.toStringAsFixed(1)} ⭐"),
                              _buildVerticalDivider(),
                              _buildStatItem(
                                  "Rate", "₹${user.hourlyRate ?? 0}/hr"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      const _ProfileSectionTitle(
                        title: "Professional Bio",
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.bio ?? "No bio added yet.",
                        style: const TextStyle(
                          color: Color(0xFFEFFF00),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.yellow,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!isOwner) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _ProfileSectionTitle(
                                title: "Work Experience"),
                            if (isCurrentUser)
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddExperienceScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: CustomColors.primaryBlue,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (user.experiences == null ||
                            user.experiences!.isEmpty)
                          const Text(
                            "No experience added yet.",
                            style: TextStyle(color: Colors.white70),
                          )
                        else
                          ...user.experiences!.map(
                            (exp) => Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exp.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B00E2),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exp.company,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exp.duration,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    exp.description,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _ProfileSectionTitle(title: "Portfolio"),
                            if (isCurrentUser)
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddPortfolioScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: CustomColors.primaryBlue,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (user.portfolio == null || user.portfolio!.isEmpty)
                          const Text(
                            "No projects added yet.",
                            style: TextStyle(color: CustomColors.textMuted),
                          )
                        else
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: user.portfolio!.length,
                              itemBuilder: (context, index) {
                                final rawItem =
                                    user.portfolio!.values.elementAt(
                                  index,
                                );
                                final Map<String, dynamic> item = rawItem is Map
                                    ? Map<String, dynamic>.from(rawItem)
                                    : {
                                        'title': 'Project ${index + 1}',
                                        'imageUrl': rawItem
                                            .toString() // Fallback if it's just a URL string
                                      };

                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC4C4C4)
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          child: CustomImageView(
                                            imagePath: item['imageUrl'] ?? '',
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          item['title'] ?? 'Untitled',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.black,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.yellow,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        const _ProfileSectionTitle(title: "Skills & Expertise"),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (user.skills ??
                                  ["Flutter", "UI Design", "Dart"])
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  backgroundColor: CustomColors.lightCard,
                                  labelStyle: const TextStyle(
                                    color: CustomColors.primaryBlue,
                                  ),
                                  side: BorderSide(
                                    color: CustomColors.primaryBlue.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _ProfileSectionTitle(title: "Resume"),
                            if (isCurrentUser)
                              IconButton(
                                onPressed: () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'doc', 'docx'],
                                  );

                                  if (result != null &&
                                      result.files.single.path != null) {
                                    final file =
                                        File(result.files.single.path!);
                                    await auth.updateResume(file);
                                  }
                                },
                                icon: const Icon(
                                  Icons.upload_file,
                                  color: CustomColors.primaryBlue,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (user.resumeUrl != null &&
                            user.resumeUrl!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CustomColors.lightCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: CustomColors.primaryBlue
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(FontAwesomeIcons.filePdf,
                                    color: Colors.red, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Professional Resume",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (user.resumeUrl != null)
                                        Text(
                                          "Click view to download",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(user.resumeUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: const Text("View"),
                                ),
                              ],
                            ),
                          )
                        else
                          const Text(
                            "No resume uploaded yet.",
                            style: TextStyle(color: CustomColors.textMuted),
                          ),
                      ],
                      if (isOwner) ...[
                        const _ProfileSectionTitle(title: "Company Details"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CustomColors.lightCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                Icons.business,
                                "Company",
                                user.companyName ?? "Not specified",
                              ),
                              const Divider(height: 24, color: Colors.white10),
                              _buildDetailRow(
                                Icons.person_outline,
                                "Manager",
                                user.managerName ?? "Not specified",
                              ),
                              const Divider(height: 24, color: Colors.white10),
                              _buildDetailRow(
                                Icons.email_outlined,
                                "Business Email",
                                user.businessEmail ?? user.email,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _ProfileSectionTitle(
                          title: "Badges & Achievements"),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _BadgeIcon(
                            icon: FontAwesomeIcons.shield,
                            color: user.isVerified ? Colors.blue : Colors.grey,
                            label: user.isVerified ? "Verified" : "Pending",
                          ),
                          const SizedBox(width: 16),
                          const _BadgeIcon(
                            icon: FontAwesomeIcons.award,
                            color: Colors.amber,
                            label: "Top Rated",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ], // Closes slivers
          ), // Closes CustomScrollView
          if (isCurrentUser)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                backgroundColor: CustomColors.primaryBlue,
                child: const Icon(Icons.edit, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: CustomColors.primaryBlue),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: CustomColors.textMuted, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: CustomColors.darkText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white10,
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  final String title;
  const _ProfileSectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _BadgeIcon({
    required this.icon,
    required this.color,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      );
}
