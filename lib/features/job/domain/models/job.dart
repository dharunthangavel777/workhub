import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String ownerId;
  final String? ownerName;
  final String? ownerPhoto;

  final String title;
  final String category;
  final String description;
  final String responsibilities;

  // Type info: 'Full-time', 'Part-time', 'Contract', 'Fixed', 'Hourly'
  final String type;
  final String postType; // 'job' or 'project'
  final String workMode; // 'Remote', 'On-site', 'Hybrid'
  final String? experienceLevel; // 'Beginner', 'Intermediate', 'Expert'
  final int? experienceMin;
  final int? experienceMax;

  final List<String> requiredSkills;
  final List<String>? preferredSkills;

  // Compensation
  final int? budgetMin;
  final int? budgetMax;
  final String?
      compensationType; // 'Monthly', 'Annual', 'Fixed', 'Hourly', 'Negotiable'

  final String location;
  final String? education;
  final String? companyName;
  final String? companyLogo;

  final int? openings;
  final int? maxApplications;
  final bool? resumeRequired;
  final List<String>? screeningQuestions;
  final DateTime? deadline;
  final String? postImage;

  final String status; // 'pending', 'approved', 'open', 'closed', etc.
  final DateTime createdAt;
  final int applicationsCount;
  final bool isVerified;
  final Map<String, dynamic>? applicants;
  final DateTime? appliedAt; // When the current user applied

  // Project-specific fields
  final List<String>? deliverables;
  final double? depositAmount;
  final bool ndaRequired;
  final String? termsAndConditions;
  final String? projectDuration;

  // Company-specific fields
  final String? companyIndustry;
  final String? companySize;
  final String? shiftType;

  Job({
    required this.id,
    required this.ownerId,
    this.ownerName,
    this.ownerPhoto,
    required this.title,
    required this.category,
    required this.description,
    this.responsibilities = '',
    required this.type,
    this.postType = 'job',
    required this.workMode,
    this.experienceLevel,
    this.experienceMin,
    this.experienceMax,
    required this.requiredSkills,
    this.preferredSkills,
    this.budgetMin,
    this.budgetMax,
    this.compensationType,
    required this.location,
    this.education,
    this.companyName,
    this.companyLogo,
    this.openings,
    this.maxApplications,
    this.resumeRequired,
    this.screeningQuestions,
    this.deadline,
    this.postImage,
    required this.status,
    required this.createdAt,
    this.applicationsCount = 0,
    this.isVerified = false,
    this.applicants,
    this.appliedAt,
    this.deliverables,
    this.depositAmount,
    this.ndaRequired = false,
    this.termsAndConditions,
    this.projectDuration,
    this.companyIndustry,
    this.companySize,
    this.shiftType,
  });

  Job copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerPhoto,
    String? title,
    String? category,
    String? description,
    String? responsibilities,
    String? type,
    String? postType,
    String? workMode,
    String? experienceLevel,
    int? experienceMin,
    int? experienceMax,
    List<String>? requiredSkills,
    List<String>? preferredSkills,
    int? budgetMin,
    int? budgetMax,
    String? compensationType,
    String? location,
    String? education,
    String? companyName,
    String? companyLogo,
    int? openings,
    int? maxApplications,
    bool? resumeRequired,
    List<String>? screeningQuestions,
    DateTime? deadline,
    String? postImage,
    String? status,
    DateTime? createdAt,
    int? applicationsCount,
    bool? isVerified,
    Map<String, dynamic>? applicants,
    DateTime? appliedAt,
    List<String>? deliverables,
    double? depositAmount,
    bool? ndaRequired,
    String? termsAndConditions,
    String? projectDuration,
    String? companyIndustry,
    String? companySize,
    String? shiftType,
  }) {
    return Job(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhoto: ownerPhoto ?? this.ownerPhoto,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      responsibilities: responsibilities ?? this.responsibilities,
      type: type ?? this.type,
      postType: postType ?? this.postType,
      workMode: workMode ?? this.workMode,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      experienceMin: experienceMin ?? this.experienceMin,
      experienceMax: experienceMax ?? this.experienceMax,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      preferredSkills: preferredSkills ?? this.preferredSkills,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      compensationType: compensationType ?? this.compensationType,
      location: location ?? this.location,
      education: education ?? this.education,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      openings: openings ?? this.openings,
      maxApplications: maxApplications ?? this.maxApplications,
      resumeRequired: resumeRequired ?? this.resumeRequired,
      screeningQuestions: screeningQuestions ?? this.screeningQuestions,
      deadline: deadline ?? this.deadline,
      postImage: postImage ?? this.postImage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      isVerified: isVerified ?? this.isVerified,
      applicants: applicants ?? this.applicants,
      appliedAt: appliedAt ?? this.appliedAt,
      deliverables: deliverables ?? this.deliverables,
      depositAmount: depositAmount ?? this.depositAmount,
      ndaRequired: ndaRequired ?? this.ndaRequired,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      projectDuration: projectDuration ?? this.projectDuration,
      companyIndustry: companyIndustry ?? this.companyIndustry,
      companySize: companySize ?? this.companySize,
      shiftType: shiftType ?? this.shiftType,
    );
  }

  factory Job.fromMap(String id, Map<String, dynamic> map,
      {String postType = 'job', DateTime? appliedAt}) {
    return Job(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'],
      ownerPhoto: map['ownerPhoto'],
      title: map['jobTitle'] ?? map['projectTitle'] ?? '',
      category: map['jobCategory'] ?? map['projectCategory'] ?? '',
      description: map['jobSummary'] ?? map['projectDescription'] ?? '',
      responsibilities: map['responsibilities'] ?? '',
      type: map['employmentType'] ?? map['projectType'] ?? 'Contract',
      postType: postType,
      workMode: map['workMode'] ?? 'Remote',
      experienceLevel: map['experienceLevel'],
      experienceMin: map['experienceMin'],
      experienceMax: map['experienceMax'],
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      preferredSkills: map['preferredSkills'] != null
          ? List<String>.from(map['preferredSkills'])
          : null,
      budgetMin: map['salaryMin'] ?? map['budgetMin'],
      budgetMax: map['salaryMax'] ?? map['budgetMax'],
      compensationType: map['salaryType'] ?? map['projectType'],
      location: map['jobLocation'] ?? map['projectLocation'] ?? '',
      education: map['education'],
      companyName: map['companyName'],
      companyLogo: map['companyLogo'],
      openings: map['openings'],
      maxApplications: map['maxApplications'],
      resumeRequired: map['resumeRequired'],
      screeningQuestions: map['screeningQuestions'] != null
          ? List<String>.from(map['screeningQuestions'])
          : null,
      deadline: map['deadlineDate'] != null
          ? (map['deadlineDate'] is Timestamp
              ? (map['deadlineDate'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['deadlineDate']))
          : null,
      postImage: map['postImage'],
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
          : DateTime.now(),
      applicationsCount: map['applicationsCount'] ?? map['proposalsCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      applicants: map['applicants'],
      appliedAt: appliedAt,
      deliverables: map['deliverables'] != null
          ? List<String>.from(map['deliverables'])
          : null,
      depositAmount: (map['depositAmount'] as num?)?.toDouble(),
      ndaRequired: map['ndaRequired'] ?? false,
      termsAndConditions: map['termsAndConditions'],
      projectDuration: map['projectDuration'],
      companyIndustry: map['companyIndustry'],
      companySize: map['companySize'],
      shiftType: map['shiftType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
      'jobTitle': title,
      'jobCategory': category,
      'jobSummary': description,
      'responsibilities': responsibilities,
      'employmentType': type,
      'workMode': workMode,
      'experienceLevel': experienceLevel,
      'experienceMin': experienceMin,
      'experienceMax': experienceMax,
      'requiredSkills': requiredSkills,
      'preferredSkills': preferredSkills,
      'salaryMin': budgetMin,
      'salaryMax': budgetMax,
      'salaryType': compensationType,
      'jobLocation': location,
      'education': education,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'openings': openings,
      'maxApplications': maxApplications,
      'resumeRequired': resumeRequired,
      'screeningQuestions': screeningQuestions,
      'deadlineDate': deadline?.millisecondsSinceEpoch,
      'postImage': postImage,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'applicationsCount': applicationsCount,
      'isVerified': isVerified,
      'applicants': applicants,
      'appliedAt': appliedAt?.millisecondsSinceEpoch,
      'deliverables': deliverables,
      'depositAmount': depositAmount,
      'ndaRequired': ndaRequired,
      'termsAndConditions': termsAndConditions,
      'projectDuration': projectDuration,
      'companyIndustry': companyIndustry,
      'companySize': companySize,
      'shiftType': shiftType,
    };
  }
}
