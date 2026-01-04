class SkillIconUtils {
  static const String _baseUrl =
      'https://raw.githubusercontent.com/devicons/devicon/master/icons';

  static final Map<String, String> _skillToIcon = {
    'flutter': 'flutter/flutter-original.svg',
    'dart': 'dart/dart-original.svg',
    'react': 'react/react-original.svg',
    'react native': 'react/react-original.svg',
    'vue': 'vuejs/vuejs-original.svg',
    'angular': 'angularjs/angularjs-original.svg',
    'java': 'java/java-original.svg',
    'python': 'python/python-original.svg',
    'javascript': 'javascript/javascript-original.svg',
    'typescript': 'typescript/typescript-original.svg',
    'node': 'nodejs/nodejs-original.svg',
    'nodejs': 'nodejs/nodejs-original.svg',
    'mongodb': 'mongodb/mongodb-original.svg',
    'firebase': 'firebase/firebase-plain.svg',
    'aws': 'amazonwebservices/amazonwebservices-original-wordmark.svg',
    'docker': 'docker/docker-original.svg',
    'kubernetes': 'kubernetes/kubernetes-plain.svg',
    'php': 'php/php-original.svg',
    'laravel': 'laravel/laravel-original.svg',
    'swift': 'swift/swift-original.svg',
    'kotlin': 'kotlin/kotlin-original.svg',
    'android': 'android/android-original.svg',
    'ios': 'apple/apple-original.svg',
    'figma': 'figma/figma-original.svg',
    'html': 'html5/html5-original.svg',
    'css': 'css3/css3-original.svg',
    'sql': 'mysql/mysql-original.svg',
    'mysql': 'mysql/mysql-original.svg',
    'postgresql': 'postgresql/postgresql-original.svg',
    'go': 'go/go-original.svg',
    'rust': 'rust/rust-plain.svg',
    'c++': 'cplusplus/cplusplus-original.svg',
    'c#': 'csharp/csharp-original.svg',
  };

  /// Returns the SVG URL for a given skill name.
  /// If no icon is found, returns null.
  static String? getIconUrl(String skill) {
    final normalizedSkill = skill.toLowerCase().trim();

    // Check for exact match
    if (_skillToIcon.containsKey(normalizedSkill)) {
      return '$_baseUrl/${_skillToIcon[normalizedSkill]}';
    }

    // Check for partial match (e.g. "React.js" matches "react")
    for (var entry in _skillToIcon.entries) {
      if (normalizedSkill.contains(entry.key)) {
        return '$_baseUrl/${entry.value}';
      }
    }

    return null;
  }
}
