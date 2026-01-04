import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProjectPostModel {
  final String id;
  final String ownerId;
  final String projectTitle;
  final String projectCategory;
  final String projectType; // Fixed, Hourly
  final String experienceLevel; // Beginner, Intermediate, Expert
  final String projectLocation;
  final String workMode; // On-site, Remote, Hybrid

  // Company Details
  final String? companyName;
  final String? companyLogo;
  final String? ownerName;
  final String? ownerPhoto;

  // Project Description
  final String projectDescription;
  final List<String> deliverables;
  final List<String>? referenceFiles;

  // Skills, Budget & Timeline
  final List<String> requiredSkills;
  final int budgetMin;
  final int budgetMax;
  final String projectDuration;
  final DateTime? startDate;

  // Proposal Settings
  final List<String>? proposalQuestions;
  final bool ndaRequired;
  final int? autoCloseLimit;
  final int? maxApplications;
  final DateTime? deadlineDate;

  // New Fields for Project Flow
  final double? depositAmount;
  final String? termsAndConditions;

  final String status; // pending, approved, rejected, open, filled, closed
  final DateTime createdAt;
  final Map<String, dynamic>? applicants;
  final int applicationsCount;

  ProjectPostModel({
    required this.id,
    required this.ownerId,
    required this.projectTitle,
    required this.projectCategory,
    required this.projectType,
    required this.experienceLevel,
    required this.projectDescription,
    required this.deliverables,
    this.referenceFiles,
    required this.requiredSkills,
    required this.budgetMin,
    required this.budgetMax,
    required this.projectDuration,
    required this.projectLocation,
    required this.workMode,
    this.startDate,
    this.proposalQuestions,
    this.ndaRequired = false,
    this.autoCloseLimit,
    this.maxApplications,
    this.deadlineDate,
    this.status = 'pending',
    required this.createdAt,
    this.applicants,
    this.applicationsCount = 0,
    this.depositAmount,
    this.termsAndConditions,
    this.companyName,
    this.companyLogo,
    this.ownerName,
    this.ownerPhoto,
  });

  factory ProjectPostModel.fromMap(String id, Map<String, dynamic> map) {
    try {
      return ProjectPostModel(
        id: id,
        ownerId: map['ownerId'] ?? '',
        projectTitle: map['projectTitle'] ?? '',
        projectCategory: map['projectCategory'] ?? '',
        projectType: map['projectType'] ?? 'Fixed',
        experienceLevel: map['experienceLevel'] ?? 'Intermediate',
        projectLocation: map['projectLocation'] ?? '',
        workMode: map['workMode'] ?? 'Remote',
        projectDescription: map['projectDescription'] ?? '',
        deliverables: List<String>.from(map['deliverables'] ?? []),
        referenceFiles: map['referenceFiles'] != null
            ? List<String>.from(map['referenceFiles'])
            : null,
        requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
        budgetMin: map['budgetMin'] ?? 0,
        budgetMax: map['budgetMax'] ?? 0,
        projectDuration: map['projectDuration'] ?? '',
        startDate: map['startDate'] != null
            ? (map['startDate'] is Timestamp
                ? (map['startDate'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(map['startDate']))
            : null,
        proposalQuestions: map['proposalQuestions'] != null
            ? List<String>.from(map['proposalQuestions'])
            : null,
        ndaRequired: map['ndaRequired'] ?? false,
        autoCloseLimit: map['autoCloseLimit'],
        maxApplications: map['maxApplications'],
        deadlineDate: map['deadlineDate'] != null
            ? (map['deadlineDate'] is Timestamp
                ? (map['deadlineDate'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(map['deadlineDate']))
            : null,
        status: map['status'] ?? 'pending',
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] is Timestamp
                ? (map['createdAt'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
            : DateTime.now(),
        applicants: map['applicants'],
        applicationsCount: map['applicationsCount'] ?? 0,
        depositAmount: (map['depositAmount'] as num?)?.toDouble(),
        termsAndConditions: map['termsAndConditions'],
        companyName: map['companyName'],
        companyLogo: map['companyLogo'],
        ownerName: map['ownerName'],
        ownerPhoto: map['ownerPhoto'],
      );
    } catch (e) {
      debugPrint("Error parsing ProjectPostModel: $e");
      return ProjectPostModel(
        id: id,
        ownerId: map['ownerId'] ?? 'error',
        projectTitle: 'Error loading project',
        projectCategory: '',
        projectType: 'Fixed',
        experienceLevel: 'Intermediate',
        projectLocation: '',
        workMode: 'Remote',
        projectDescription: '',
        deliverables: [],
        requiredSkills: [],
        budgetMin: 0,
        budgetMax: 0,
        projectDuration: '',
        createdAt: DateTime.now(),
        status: 'error',
        applicationsCount: 0,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'projectTitle': projectTitle,
      'projectCategory': projectCategory,
      'projectType': projectType,
      'experienceLevel': experienceLevel,
      'projectLocation': projectLocation,
      'workMode': workMode,
      'projectDescription': projectDescription,
      'deliverables': deliverables,
      'referenceFiles': referenceFiles,
      'requiredSkills': requiredSkills,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'projectDuration': projectDuration,
      'startDate': startDate?.millisecondsSinceEpoch,
      'proposalQuestions': proposalQuestions,
      'ndaRequired': ndaRequired,
      'autoCloseLimit': autoCloseLimit,
      'maxApplications': maxApplications,
      'deadlineDate': deadlineDate?.millisecondsSinceEpoch,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'applicants': applicants,
      'applicationsCount': applicationsCount,
      'depositAmount': depositAmount,
      'termsAndConditions': termsAndConditions,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
    };
  }
}
