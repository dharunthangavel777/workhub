class ResumeData {
  final String? name;
  final String? email;
  final String? phone;
  final String? location;
  final String? bio;
  final ResumeSkills skills;
  final List<WorkExperience> workExperience;
  final List<Education> education;
  final List<Project> projects;
  final List<Certification> certifications;
  final String? category;
  final Map<String, dynamic>? rawData;

  ResumeData({
    this.name,
    this.email,
    this.phone,
    this.location,
    this.bio,
    this.skills = const ResumeSkills(),
    this.workExperience = const [],
    this.education = const [],
    this.projects = const [],
    this.certifications = const [],
    this.category,
    this.rawData,
  });

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    final parsedData = json['parsedData'] as Map<String, dynamic>? ?? {};

    return ResumeData(
      name: parsedData['name'] as String?,
      email: parsedData['email'] as String?,
      phone: parsedData['phone'] as String?,
      location: parsedData['location'] as String?,
      bio: parsedData['bio'] as String?,
      category: parsedData['category'] as String?,
      skills: ResumeSkills.fromJson(parsedData['skills'] as Map<String, dynamic>? ?? {}),
      workExperience: (parsedData['workExperience'] as List<dynamic>?)
              ?.map((e) => WorkExperience.fromJson(e))
              .toList() ??
          [],
      education: (parsedData['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e))
              .toList() ??
          [],
      projects: (parsedData['projects'] as List<dynamic>?)
              ?.map((e) => Project.fromJson(e))
              .toList() ??
          [],
      certifications: (parsedData['certifications'] as List<dynamic>?)
              ?.map((e) => Certification.fromJson(e))
              .toList() ??
          [],
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'bio': bio,
      'category': category,
      'skills': skills.toJson(),
      'workExperience': workExperience.map((e) => e.toJson()).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'projects': projects.map((e) => e.toJson()).toList(),
      'certifications': certifications.map((e) => e.toJson()).toList(),
    };
  }
}

class ResumeSkills {
  final List<SkillWithConfidence> technical;
  final List<SkillWithConfidence> tools;
  final List<SkillWithConfidence> soft;

  const ResumeSkills({
    this.technical = const [],
    this.tools = const [],
    this.soft = const [],
  });

  factory ResumeSkills.fromJson(Map<String, dynamic> json) {
    return ResumeSkills(
      technical: (json['technical'] as List<dynamic>?)
              ?.map((e) => SkillWithConfidence.fromJson(e))
              .toList() ??
          [],
      tools: (json['tools'] as List<dynamic>?)
              ?.map((e) => SkillWithConfidence.fromJson(e))
              .toList() ??
          [],
      soft: (json['soft'] as List<dynamic>?)
              ?.map((e) => SkillWithConfidence.fromJson(e))
              .toList() ??
          [],
    );
  }

  List<SkillWithConfidence> get allSkills => [...technical, ...tools, ...soft];
  bool get isNotEmpty => allSkills.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'technical': technical.map((e) => e.toJson()).toList(),
      'tools': tools.map((e) => e.toJson()).toList(),
      'soft': soft.map((e) => e.toJson()).toList(),
    };
  }
}

class SkillWithConfidence {
  final String name;
  final double confidence;

  SkillWithConfidence({required this.name, required this.confidence});

  factory SkillWithConfidence.fromJson(Map<String, dynamic> json) {
    return SkillWithConfidence(
      name: json['name'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
    };
  }
}

class WorkExperience {
  final String? title;
  final String? company;
  final String? duration;
  final String? description;

  WorkExperience({
    this.title,
    this.company,
    this.duration,
    this.description,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      title: json['title'] as String?,
      company: json['company'] as String?,
      duration: json['duration'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'duration': duration,
      'description': description,
    };
  }
}

class Education {
  final String? degree;
  final String? institution;
  final String? year;

  Education({this.degree, this.institution, this.year});

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree'] as String?,
      institution: json['institution'] as String?,
      year: json['year'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'institution': institution,
      'year': year,
    };
  }
}

class Project {
  final String? title;
  final String? description;

  Project({this.title, this.description});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}

class Certification {
  final String? name;
  final String? issuer;
  final String? date;

  Certification({this.name, this.issuer, this.date});

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] as String?,
      issuer: json['issuer'] as String?,
      date: json['date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'date': date,
    };
  }
}



