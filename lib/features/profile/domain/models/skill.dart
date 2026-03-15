class SkillModel {
  final String name;
  final bool isVerified;
  final String verificationSource; // 'ai', 'manual', 'test'
  final double confidence; // 0.0 to 1.0

  SkillModel({
    required this.name,
    this.isVerified = false,
    this.verificationSource = 'none',
    this.confidence = 0.0,
  });

  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      name: map['name'] ?? '',
      isVerified: map['isVerified'] ?? false,
      verificationSource: map['verificationSource'] ?? 'none',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
    );
  }

  factory SkillModel.fromString(String name) {
    return SkillModel(name: name);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isVerified': isVerified,
      'verificationSource': verificationSource,
      'confidence': confidence,
    };
  }

  @override
  String toString() => name;
}
