class ApiConstants {
  // Toggle this for production
  static const bool isProduction = true;

  // Local development URL
  static const String localUrl = 'http://localhost:3000';

  // Production URL from Railway
  static const String productionUrl =
      'https://work-hub-backend-production.up.railway.app';

  static String get baseUrl => isProduction ? productionUrl : localUrl;
  static String get apiBaseUrl => '$baseUrl/api';
  static String get socketUrl => baseUrl;
}



