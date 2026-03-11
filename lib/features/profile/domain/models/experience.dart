class ExperienceModel {
  final String title;
  final String company;
  final String duration;
  final String description;

  ExperienceModel({
    required this.title,
    required this.company,
    required this.duration,
    required this.description,
  });

  factory ExperienceModel.fromMap(Map<dynamic, dynamic> map) {
    return ExperienceModel(
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      duration: map['duration'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'duration': duration,
      'description': description,
    };
  }
}



