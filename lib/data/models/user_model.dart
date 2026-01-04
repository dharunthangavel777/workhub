import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'experience_model.dart';

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
  final List<String>? skills;
  final List<String>? badges;
  final Map<String, dynamic>? portfolio;
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
  final String? companyName;
  final String? companyWebsite;
  final String? managerName;
  final String activeMode; // 'job' or 'freelancer'
  final String subscriptionTier; // 'Free', 'Pro', 'Elite'
  final int? subscriptionExpiry;
  final double walletBalance;

  // Owner Request & Trial Fields
  final String ownerRequestStatus; // 'none', 'pending', 'approved', 'rejected'
  final Map<String, dynamic>? ownerRequestData;
  final String? rejectionReason;
  final DateTime? trialStartDate;
  final bool isTrialActive;
  final bool hasSeenSubscription;

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
    this.companyName,
    this.companyWebsite,
    this.managerName,
    this.activeMode = 'job',
    this.subscriptionTier = 'Free',
    this.subscriptionExpiry,
    this.walletBalance = 0.0,
    this.ownerRequestStatus = 'none',
    this.ownerRequestData,
    this.rejectionReason,
    this.trialStartDate,
    this.isTrialActive = false,
    this.hasSeenSubscription = false,
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
        skills: _safeList(map['skills']),
        badges: _safeList(map['badges']),
        portfolio: _safeMap(map['portfolio']),
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
        companyName: map['companyName']?.toString(),
        companyWebsite: map['companyWebsite']?.toString(),
        managerName: map['managerName']?.toString(),
        activeMode: map['activeMode']?.toString() ?? 'job',
        subscriptionTier: map['subscriptionTier']?.toString() ?? 'Free',
        subscriptionExpiry:
            map['subscriptionExpiry'] is int ? map['subscriptionExpiry'] : null,
        walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
        ownerRequestStatus: map['ownerRequestStatus']?.toString() ?? 'none',
        ownerRequestData: map['ownerRequestData'] is Map<String, dynamic>
            ? map['ownerRequestData']
            : null,
        rejectionReason: map['rejectionReason']?.toString(),
        trialStartDate: _parseDate(map['trialStartDate']),
        isTrialActive: map['isTrialActive'] == true,
        hasSeenSubscription: map['hasSeenSubscription'] == true,
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
      'skills': skills,
      'badges': badges,
      'portfolio': portfolio,
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
      'companyName': companyName,
      'companyWebsite': companyWebsite,
      'managerName': managerName,
      'activeMode': activeMode,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiry': subscriptionExpiry,
      'walletBalance': walletBalance,
      'ownerRequestStatus': ownerRequestStatus,
      'ownerRequestData': ownerRequestData,
      'rejectionReason': rejectionReason,
      'trialStartDate': trialStartDate?.millisecondsSinceEpoch,
      'isTrialActive': isTrialActive,
      'hasSeenSubscription': hasSeenSubscription,
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
    List<String>? skills,
    List<String>? badges,
    Map<String, dynamic>? portfolio,
    String? businessEmail,
    bool? isVerified,
    bool? isFirstLogin,
    String? location,
    String? jobCategory,
    String? resumeUrl,
    String? companyName,
    String? companyWebsite,
    String? managerName,
    String? activeMode,
    String? subscriptionTier,
    int? subscriptionExpiry,
    double? walletBalance,
    String? ownerRequestStatus,
    Map<String, dynamic>? ownerRequestData,
    String? rejectionReason,
    DateTime? trialStartDate,
    bool? isTrialActive,
    bool? hasSeenSubscription,
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
      companyName: companyName ?? this.companyName,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      managerName: managerName ?? this.managerName,
      activeMode: activeMode ?? this.activeMode,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      walletBalance: walletBalance ?? this.walletBalance,
      ownerRequestStatus: ownerRequestStatus ?? this.ownerRequestStatus,
      ownerRequestData: ownerRequestData ?? this.ownerRequestData,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      hasSeenSubscription: hasSeenSubscription ?? this.hasSeenSubscription,
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
    );
  }

  int get profileCompletion {
    double score = 0.0;

    // 1. Identity (20%)
    if (photoURL != null && photoURL!.isNotEmpty) score += 10.0;
    if (displayName.isNotEmpty) score += 10.0;

    // 2. Professional (30%)
    if (bio != null && bio!.isNotEmpty) score += 15.0;
    if (jobCategory != null && jobCategory!.isNotEmpty) score += 15.0;

    // 3. Skills & Work (30%) - Skills bumped to 20
    if (skills != null && skills!.isNotEmpty) score += 20.0;
    if (portfolio != null && portfolio!.isNotEmpty) score += 10.0;

    // 4. Meta & Documents (20%)
    if (location != null && location!.isNotEmpty) score += 10.0;
    if (resumeUrl != null && resumeUrl!.isNotEmpty) score += 10.0;

    // Sum: 10+10+15+15+20+10+10+10 = 100.

    return score.round();
  }

  List<String> get missingProfileFields {
    final List<String> missing = [];
    if (photoURL == null || photoURL!.isEmpty) missing.add("Profile Photo");
    if (displayName.isEmpty) missing.add("Display Name");
    if (bio == null || bio!.isEmpty) missing.add("Bio");
    if (jobCategory == null || jobCategory!.isEmpty)
      missing.add("Job Category");
    if (skills == null || skills!.isEmpty) missing.add("Skills");
    if (portfolio == null || portfolio!.isEmpty)
      missing.add("Portfolio Project");
    if (location == null || location!.isEmpty) missing.add("Location");
    if (resumeUrl == null || resumeUrl!.isEmpty) missing.add("Resume");
    return missing;
  }
}
