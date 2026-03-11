enum ResumeParseErrorType {
  networkError, // Internet connection issues
  apiKeyMissing, // Configuration error
  apiQuotaExceeded, // Rate limit/quota
  invalidFormat, // Bad file or response format
  parsingFailed, // AI couldn't extract data
  timeout, // Request took too long
  providerDown, // Provider unavailable
  unknown // Unexpected errors
}

class ResumeParseError implements Exception {
  final ResumeParseErrorType type;
  final String message;
  final String userMessage;
  final bool isRetryable;
  final String? providerName;

  ResumeParseError({
    required this.type,
    required this.message,
    required this.userMessage,
    required this.isRetryable,
    this.providerName,
  });

  factory ResumeParseError.networkError([String? provider]) {
    return ResumeParseError(
      type: ResumeParseErrorType.networkError,
      message: 'Network connection failed',
      userMessage:
          'No internet connection. Please check your network and try again.',
      isRetryable: true,
      providerName: provider,
    );
  }

  factory ResumeParseError.timeout([String? provider]) {
    return ResumeParseError(
      type: ResumeParseErrorType.timeout,
      message: 'Request timed out after 30 seconds',
      userMessage: 'Request took too long. Trying another provider...',
      isRetryable: true,
      providerName: provider,
    );
  }

  factory ResumeParseError.apiQuotaExceeded([String? provider]) {
    return ResumeParseError(
      type: ResumeParseErrorType.apiQuotaExceeded,
      message: 'API quota exceeded',
      userMessage: 'Provider limit reached. Trying backup provider...',
      isRetryable: true,
      providerName: provider,
    );
  }

  factory ResumeParseError.parsingFailed([String? provider]) {
    return ResumeParseError(
      type: ResumeParseErrorType.parsingFailed,
      message: 'Could not extract resume data',
      userMessage:
          'Could not read resume. Please ensure file is clear and readable.',
      isRetryable: false,
      providerName: provider,
    );
  }

  factory ResumeParseError.invalidFormat([String? provider]) {
    return ResumeParseError(
      type: ResumeParseErrorType.invalidFormat,
      message: 'Invalid response format from AI',
      userMessage:
          'Unexpected response format. Please try again or fill manually.',
      isRetryable: true,
      providerName: provider,
    );
  }

  factory ResumeParseError.apiKeyMissing([String? provider]) {
    return ResumeParseError(
      type: ResumeParseErrorType.apiKeyMissing,
      message: 'API Key/Token missing',
      userMessage: 'AI service not configured. Please contact support.',
      isRetryable: false,
      providerName: provider,
    );
  }

  factory ResumeParseError.allProvidersFailed() {
    return ResumeParseError(
      type: ResumeParseErrorType.unknown,
      message: 'All AI providers failed',
      userMessage:
          'All AI providers are currently unavailable. Please try again later or fill manually.',
      isRetryable: false,
    );
  }

  @override
  String toString() {
    return 'ResumeParseError(type: $type, message: $message, provider: $providerName)';
  }
}



