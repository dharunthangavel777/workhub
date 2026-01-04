class Education {
  final String? degree;
  final String? institution;
  final String? year;

  Education({this.degree, this.institution, this.year});

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree'],
      institution: json['institution'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        'year': year,
      };
}

class Project {
  final String? title;
  final String? description;
  final List<String> techStack;

  Project({this.title, this.description, this.techStack = const []});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      title: json['title'],
      description: json['description'],
      techStack: (json['techStack'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'techStack': techStack,
      };
}

class WorkExperience {
  final String? title;
  final String? company;
  final String? duration;
  final String? description;

  WorkExperience({this.title, this.company, this.duration, this.description});

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      title: json['title'],
      company: json['company'],
      duration: json['duration'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'company': company,
        'duration': duration,
        'description': description,
      };
}

class ConfidenceScores {
  final double? name;
  final double? email;
  final double? location;
  final double? education;
  final double? skills;
  final double? projects;

  ConfidenceScores({
    this.name,
    this.email,
    this.location,
    this.education,
    this.skills,
    this.projects,
  });

  factory ConfidenceScores.fromJson(Map<String, dynamic> json) {
    return ConfidenceScores(
      name: (json['name'] as num?)?.toDouble(),
      email: (json['email'] as num?)?.toDouble(),
      location: (json['location'] as num?)?.toDouble(),
      education: (json['education'] as num?)?.toDouble(),
      skills: (json['skills'] as num?)?.toDouble(),
      projects: (json['projects'] as num?)?.toDouble(),
    );
  }
}

class ResumeData {
  final String? name;
  final String? email;
  final String? phone;
  final String? location;
  final String? bio;
  final String? category;
  final List<Education> education;
  final List<String> skills;
  final List<Project> projects;
  final List<WorkExperience> workExperience;
  final ConfidenceScores? confidenceScores;

  String? get fullName => name;

  ResumeData({
    this.name,
    this.email,
    this.phone,
    this.location,
    this.bio,
    this.category,
    this.education = const [],
    this.skills = const [],
    this.projects = const [],
    this.workExperience = const [],
    this.confidenceScores,
  });

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    final parsed = json['parsedData'] ?? {};
    return ResumeData(
      name: parsed['name'],
      email: parsed['email'],
      phone: parsed['phone'],
      location: parsed['location'],
      bio: parsed['bio'],
      category: parsed['category'],
      education: (parsed['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e))
              .toList() ??
          [],
      skills: (parsed['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      projects: (parsed['projects'] as List<dynamic>?)
              ?.map((e) => Project.fromJson(e))
              .toList() ??
          [],
      workExperience: (parsed['workExperience'] as List<dynamic>?)
              ?.map((e) => WorkExperience.fromJson(e))
              .toList() ??
          [],
      confidenceScores: json['confidenceScores'] != null
          ? ConfidenceScores.fromJson(json['confidenceScores'])
          : null,
    );
  }
}
