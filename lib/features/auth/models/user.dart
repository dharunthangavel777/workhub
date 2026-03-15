import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../profile/domain/models/experience.dart';
import '../../profile/domain/models/skill.dart';

enum UserRole { worker, businessOwner, admin, none }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserRole role;
  final String? bannerImage;
  final String? username;
  final String? bio;
  final List<SkillModel>? skills;
  final List<String>? badges;
  final Map<String, dynamic>? portfolio;
  final List<Map<String, dynamic>>? certifications;
  final DateTime? createdAt;
  final Map<String, bool>? followers;
  final Map<String, bool>? following;
  final List<ExperienceModel>? experiences;
  final String? businessEmail;
  final bool isVerified;
  final bool isFirstLogin;
  final String? location;
  final String? jobCategory;
  final String? resumeUrl;
  final String? managerName;
  final String activeMode; // 'job' or 'freelancer'
  final String subscriptionTier; // 'Free', 'Pro', 'Elite'
  final int? subscriptionExpiry;
  final double walletBalance;

  // New Fields - Personal
  final String? fullName;
  final double? totalExperience;

  // New Fields - Job Mode (Worker)
  final String? currentCompany;
  final int? expectedSalary;
  final List<String>? jobPreference;

  // New Fields - Freelance Mode
  final int? hourlyRate;
  final String? availability;
  final int completedProjects;
  final double rating;

  // NEW FIELDS for wallet system
  final double totalEarnings; // Total earned across all projects
  final double pendingClearance; // Funds in escrow
  final int ratingsCount; // Number of ratings received
  final List<Map<String, dynamic>>? bankAccounts; // Bank account details

  final String? phoneNumber;
  final String? walletAddress;
  final bool isBanned;

  // Saved Items
  final List<String> savedJobIds;
  final List<String> savedProjectIds;
  final String ownerRequestStatus; // 'none', 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final Map<String, dynamic>? ownerRequestData;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.role = UserRole.none,
    this.bannerImage,
    this.username,
    this.bio,
    this.skills,
    this.badges,
    this.portfolio,
    this.certifications,
    this.createdAt,
    this.followers,
    this.following,
    this.experiences,
    this.businessEmail,
    this.isVerified = false,
    this.isFirstLogin = true,
    this.location,
    this.jobCategory,
    this.resumeUrl,
    this.managerName,
    this.activeMode = 'job',
    this.subscriptionTier = 'Free',
    this.subscriptionExpiry,
    this.walletBalance = 0.0,
    this.fullName,
    this.totalExperience,
    this.currentCompany,
    this.expectedSalary,
    this.jobPreference,
    this.hourlyRate,
    this.availability,
    this.completedProjects = 0,
    this.rating = 0.0,
    this.totalEarnings = 0.0,
    this.pendingClearance = 0.0,
    this.ratingsCount = 0,
    this.bankAccounts,
    this.phoneNumber,
    this.walletAddress,
    this.isBanned = false,
    this.savedJobIds = const [],
    this.savedProjectIds = const [],
    this.ownerRequestStatus = 'none',
    this.rejectionReason,
    this.ownerRequestData,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        uid: map['uid']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? 'User',
        photoURL: map['photoURL']?.toString(),
        role: _parseRole(map['role']?.toString()),
        bannerImage: map['bannerImage']?.toString(),
        username: map['username']?.toString(),
        bio: map['bio']?.toString(),
        skills: map['skills'] is List
            ? (map['skills'] as List).map((e) {
                if (e is Map) return SkillModel.fromMap(Map<String, dynamic>.from(e));
                return SkillModel.fromString(e.toString());
              }).toList()
            : [],
        badges: _safeList(map['badges']),
        portfolio: _safeMap(map['portfolio']),
        certifications: map['certifications'] is List
            ? (map['certifications'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [],
        createdAt: _parseDate(map['createdAt']),
        followers: map['followers'] is Map
            ? Map<String, bool>.from(map['followers'])
            : {},
        following: map['following'] is Map
            ? Map<String, bool>.from(map['following'])
            : {},
        experiences: map['experiences'] is List
            ? (map['experiences'] as List)
                .map((e) => ExperienceModel.fromMap(e))
                .toList()
            : [],
        businessEmail: map['businessEmail']?.toString(),
        isVerified: map['isVerified'] == true,
        isFirstLogin: map['isFirstLogin'] ?? true,
        location: map['location']?.toString(),
        jobCategory: map['jobCategory']?.toString(),
        resumeUrl: map['resumeUrl']?.toString(),
        managerName: map['managerName']?.toString(),
        activeMode: map['activeMode']?.toString() ?? 'job',
        subscriptionTier: map['subscriptionTier']?.toString() ?? 'Free',
        subscriptionExpiry:
            map['subscriptionExpiry'] is int ? map['subscriptionExpiry'] : null,
        walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
        fullName: map['fullName']?.toString(),
        totalExperience: (map['totalExperience'] ?? 0.0).toDouble(),
        currentCompany: map['currentCompany']?.toString(),
        expectedSalary:
            map['expectedSalary'] is int ? map['expectedSalary'] : null,
        jobPreference: _safeList(map['jobPreference']),
        hourlyRate: map['hourlyRate'] is int ? map['hourlyRate'] : null,
        availability: map['availability']?.toString(),
        completedProjects:
            map['completedProjects'] is int ? map['completedProjects'] : 0,
        rating: (map['rating'] ?? 0.0).toDouble(),
        totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
        pendingClearance: (map['pendingClearance'] ?? 0.0).toDouble(),
        ratingsCount: map['ratingsCount'] is int ? map['ratingsCount'] : 0,
        bankAccounts: map['bankAccounts'] is List
            ? (map['bankAccounts'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : null,
        phoneNumber: map['phoneNumber']?.toString(),
        walletAddress: map['walletAddress']?.toString(),
        isBanned: map['isBanned'] == true,
        savedJobIds: List<String>.from(map['savedJobIds'] ?? []),
        savedProjectIds: List<String>.from(map['savedProjectIds'] ?? []),
        ownerRequestStatus: map['ownerRequestStatus']?.toString() ?? 'none',
        rejectionReason: map['rejectionReason']?.toString(),
        ownerRequestData: _safeMap(map['ownerRequestData']),
      );
    } catch (e, stack) {
      debugPrint("UserModel.fromMap Error: $e");
      debugPrint("Stack: $stack");
      // Return a minimal valid model to prevent total crash
      return UserModel(
        uid: map['uid']?.toString() ?? 'unknown',
        email: map['email']?.toString() ?? '',
        displayName: 'Error User',
      );
    }
  }

  static Map<String, dynamic> _safeMap(dynamic val) {
    if (val is Map) {
      return Map<String, dynamic>.from(val);
    }
    return {};
  }

  static List<String> _safeList(dynamic val) {
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.name,
      'bannerImage': bannerImage,
      'username': username,
      'bio': bio,
      'skills': skills?.map((e) => e.toMap()).toList(),
      'badges': badges,
      'portfolio': portfolio,
      'certifications': certifications,
      'createdAt': createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'followers': followers,
      'following': following,
      'experiences': experiences?.map((e) => e.toMap()).toList(),
      'businessEmail': businessEmail,
      'isVerified': isVerified,
      'isFirstLogin': isFirstLogin,
      'location': location,
      'jobCategory': jobCategory,
      'resumeUrl': resumeUrl,
      'managerName': managerName,
      'activeMode': activeMode,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiry': subscriptionExpiry,
      'walletBalance': walletBalance,
      'fullName': fullName,
      'totalExperience': totalExperience,
      'currentCompany': currentCompany,
      'expectedSalary': expectedSalary,
      'jobPreference': jobPreference,
      'hourlyRate': hourlyRate,
      'availability': availability,
      'completedProjects': completedProjects,
      'rating': rating,
      'totalEarnings': totalEarnings,
      'pendingClearance': pendingClearance,
      'ratingsCount': ratingsCount,
      'bankAccounts': bankAccounts,
      'phoneNumber': phoneNumber,
      'walletAddress': walletAddress,
      'isBanned': isBanned,
      'savedJobIds': savedJobIds,
      'savedProjectIds': savedProjectIds,
      'ownerRequestStatus': ownerRequestStatus,
      'rejectionReason': rejectionReason,
      'ownerRequestData': ownerRequestData,
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'worker':
        return UserRole.worker;
      case 'businessOwner':
        return UserRole.businessOwner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.none;
    }
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    UserRole? role,
    String? bannerImage,
    String? username,
    String? bio,
    List<SkillModel>? skills,
    List<String>? badges,
    Map<String, dynamic>? portfolio,
    List<Map<String, dynamic>>? certifications,
    String? businessEmail,
    bool? isVerified,
    bool? isFirstLogin,
    String? location,
    String? jobCategory,
    String? resumeUrl,
    String? managerName,
    String? activeMode,
    String? subscriptionTier,
    int? subscriptionExpiry,
    double? walletBalance,
    String? fullName,
    double? totalExperience,
    String? currentCompany,
    int? expectedSalary,
    List<String>? jobPreference,
    int? hourlyRate,
    String? availability,
    int? completedProjects,
    double? rating,
    double? totalEarnings,
    double? pendingClearance,
    int? ratingsCount,
    List<Map<String, dynamic>>? bankAccounts,
    String? phoneNumber,
    String? walletAddress,
    bool? isBanned,
    List<String>? savedJobIds,
    List<String>? savedProjectIds,
    List<ExperienceModel>? experiences,
    String? ownerRequestStatus,
    String? rejectionReason,
    Map<String, dynamic>? ownerRequestData,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bannerImage: bannerImage ?? this.bannerImage,
      username: username ?? this.username,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      badges: badges ?? this.badges,
      portfolio: portfolio ?? this.portfolio,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt,
      followers: followers,
      following: following,
      experiences: experiences ?? this.experiences,
      businessEmail: businessEmail ?? this.businessEmail,
      isVerified: isVerified ?? this.isVerified,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      location: location ?? this.location,
      jobCategory: jobCategory ?? this.jobCategory,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      managerName: managerName ?? this.managerName,
      activeMode: activeMode ?? this.activeMode,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      walletBalance: walletBalance ?? this.walletBalance,
      fullName: fullName ?? this.fullName,
      totalExperience: totalExperience ?? this.totalExperience,
      currentCompany: currentCompany ?? this.currentCompany,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      jobPreference: jobPreference ?? this.jobPreference,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availability: availability ?? this.availability,
      completedProjects: completedProjects ?? this.completedProjects,
      rating: rating ?? this.rating,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingClearance: pendingClearance ?? this.pendingClearance,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      walletAddress: walletAddress ?? this.walletAddress,
      isBanned: isBanned ?? this.isBanned,
      savedJobIds: savedJobIds ?? this.savedJobIds,
      savedProjectIds: savedProjectIds ?? this.savedProjectIds,
      ownerRequestStatus: ownerRequestStatus ?? this.ownerRequestStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      ownerRequestData: ownerRequestData ?? this.ownerRequestData,
    );
  }

  int get profileCompletion {
    double score = 0.0;

    // 1. Profile Image (10%)
    if (photoURL != null && photoURL!.isNotEmpty) score += 10.0;

    // 2. User Name (10%)
    if ((username != null && username!.isNotEmpty) ||
        (displayName.isNotEmpty && displayName != 'User')) {
      score += 10.0;
    }

    // 3. Bio (15%)
    if (bio != null && bio!.isNotEmpty) score += 15.0;

    // 4. Location (10%)
    if (location != null && location!.isNotEmpty) score += 10.0;

    // 5. Job Category (10%)
    if (jobCategory != null && jobCategory!.isNotEmpty) score += 10.0;

    // 6. Skills (15%)
    if (skills != null && skills!.isNotEmpty) score += 15.0;

    // 7. Experiences (15%)
    if (experiences != null && experiences!.isNotEmpty) score += 15.0;

    // 8. Certifications (10%)
    if (certifications != null && certifications!.isNotEmpty) score += 10.0;

    // 9. Resume (5%)
    if (resumeUrl != null && resumeUrl!.isNotEmpty) score += 5.0;

    return score.round();
  }

  List<String> get missingProfileFields {
    final List<String> missing = [];
    if (photoURL == null || photoURL!.isEmpty) missing.add("Profile Photo");
    if ((username == null || username!.isEmpty) &&
        (displayName.isEmpty || displayName == 'User')) {
      missing.add("Name/Username");
    }
    if (bio == null || bio!.isEmpty) missing.add("Bio");
    if (location == null || location!.isEmpty) missing.add("Location");
    if (jobCategory == null || jobCategory!.isEmpty) {
      missing.add("Job Category");
    }
    if (skills == null || skills!.isEmpty) missing.add("Skills");
    if (experiences == null || experiences!.isEmpty) missing.add("Work Experience");
    if (certifications == null || certifications!.isEmpty) missing.add("Certifications");
    if (resumeUrl == null || resumeUrl!.isEmpty) missing.add("Resume");
    return missing;
  }
}



