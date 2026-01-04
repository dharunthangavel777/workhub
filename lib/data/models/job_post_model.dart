import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class JobPostModel {
  final String id;
  final String ownerId;
  final String jobTitle;
  final String jobCategory;
  final String employmentType; // Full-time, Part-time, Internship, Contract
  final String workMode; // On-site, Remote, Hybrid
  final int experienceMin;
  final int experienceMax;
  final String? ownerName;
  final String? ownerPhoto;

  // Company Details
  final String companyName;
  final String? companyLogo;
  final String companyIndustry;
  final String? companySize;
  final String? companyWebsite;

  // Job Description
  final String jobSummary;
  final String responsibilities;
  final List<String> requiredSkills;
  final List<String>? preferredSkills;

  // Salary & Location
  final int? salaryMin;
  final int? salaryMax;
  final String salaryType; // Monthly, Annual, Negotiable
  final String jobLocation;
  final String? shiftType;
  final String education;

  // Application Settings
  final int openings;
  final String applyMethod; // In-App, External
  final bool resumeRequired;
  final List<String>? screeningQuestions;
  final int? maxApplications;
  final DateTime? deadlineDate;

  final String status; // pending, approved, rejected, filled, closed
  final DateTime createdAt;
  final Map<String, dynamic>? applicants;
  final int applicationsCount;

  JobPostModel({
    required this.id,
    required this.ownerId,
    required this.jobTitle,
    required this.jobCategory,
    required this.employmentType,
    required this.workMode,
    required this.experienceMin,
    required this.experienceMax,
    required this.companyName,
    this.companyLogo,
    required this.companyIndustry,
    this.companySize,
    this.companyWebsite,
    required this.jobSummary,
    required this.responsibilities,
    required this.requiredSkills,
    this.preferredSkills,
    this.salaryMin,
    this.salaryMax,
    required this.salaryType,
    required this.jobLocation,
    this.shiftType,
    required this.education,
    required this.openings,
    required this.applyMethod,
    this.resumeRequired = true,
    this.screeningQuestions,
    this.maxApplications,
    this.deadlineDate,
    this.status = 'pending',
    required this.createdAt,
    this.applicants,
    this.applicationsCount = 0,
    this.ownerName,
    this.ownerPhoto,
  });

  factory JobPostModel.fromMap(String id, Map<String, dynamic> map) {
    try {
      return JobPostModel(
        id: id,
        ownerId: map['ownerId'] ?? '',
        jobTitle: map['jobTitle'] ?? '',
        jobCategory: map['jobCategory'] ?? '',
        employmentType: map['employmentType'] ?? 'Full-time',
        workMode: map['workMode'] ?? 'Remote',
        experienceMin: map['experienceMin'] ?? 0,
        experienceMax: map['experienceMax'] ?? 0,
        companyName: map['companyName'] ?? '',
        companyLogo: map['companyLogo'],
        companyIndustry: map['companyIndustry'] ?? '',
        companySize: map['companySize'],
        companyWebsite: map['companyWebsite'],
        jobSummary: map['jobSummary'] ?? '',
        responsibilities: map['responsibilities'] ?? '',
        requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
        preferredSkills: map['preferredSkills'] != null
            ? List<String>.from(map['preferredSkills'])
            : null,
        salaryMin: map['salaryMin'],
        salaryMax: map['salaryMax'],
        salaryType: map['salaryType'] ?? 'Monthly',
        jobLocation: map['jobLocation'] ?? '',
        shiftType: map['shiftType'] ?? '',
        education: map['education'] ?? 'Any Graduate',
        openings: map['openings'] ?? 1,
        applyMethod: map['applyMethod'] ?? 'In-App',
        resumeRequired: map['resumeRequired'] ?? true,
        screeningQuestions: map['screeningQuestions'] != null
            ? List<String>.from(map['screeningQuestions'])
            : null,
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
        ownerName: map['ownerName'],
        ownerPhoto: map['ownerPhoto'],
      );
    } catch (e) {
      debugPrint("Error parsing JobPostModel: $e");
      // Return a minimal valid model to prevent stream failure
      return JobPostModel(
        id: id,
        ownerId: map['ownerId'] ?? 'error',
        jobTitle: 'Error loading job',
        jobCategory: '',
        employmentType: 'Full-time',
        workMode: 'Remote',
        experienceMin: 0,
        experienceMax: 0,
        companyName: 'Error',
        companyIndustry: '',
        jobSummary: '',
        responsibilities: '',
        requiredSkills: [],
        salaryType: 'Monthly',
        jobLocation: '',
        education: '',
        openings: 0,
        applyMethod: 'In-App',
        createdAt: DateTime.now(),
        status: 'error',
        applicationsCount: 0,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'jobTitle': jobTitle,
      'jobCategory': jobCategory,
      'employmentType': employmentType,
      'workMode': workMode,
      'experienceMin': experienceMin,
      'experienceMax': experienceMax,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'companyIndustry': companyIndustry,
      'companySize': companySize,
      'companyWebsite': companyWebsite,
      'jobSummary': jobSummary,
      'responsibilities': responsibilities,
      'requiredSkills': requiredSkills,
      'preferredSkills': preferredSkills,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryType': salaryType,
      'jobLocation': jobLocation,
      'shiftType': shiftType,
      'education': education,
      'openings': openings,
      'applyMethod': applyMethod,
      'resumeRequired': resumeRequired,
      'screeningQuestions': screeningQuestions,
      'maxApplications': maxApplications,
      'deadlineDate': deadlineDate?.millisecondsSinceEpoch,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'applicants': applicants,
      'applicationsCount': applicationsCount,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
    };
  }
}
