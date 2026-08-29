/// Base class for all translation errors
sealed class TranslationError implements Exception {
  final String message;
  final String? engineId;
  final dynamic cause;

  const TranslationError(this.message, {this.engineId, this.cause});

  @override
  String toString() => 'TranslationError($engineId): $message';
}

class NetworkError extends TranslationError {
  const NetworkError(super.message, {super.engineId, super.cause});
}

class TimeoutError extends TranslationError {
  const TimeoutError(super.message, {super.engineId, super.cause});
}

class AuthenticationError extends TranslationError {
  const AuthenticationError(super.message, {super.engineId, super.cause});
}

class RateLimitError extends TranslationError {
  final Duration? retryAfter;
  const RateLimitError(super.message, {this.retryAfter, super.engineId, super.cause});
}

class InvalidRequestError extends TranslationError {
  const InvalidRequestError(super.message, {super.engineId, super.cause});
}

class UnsupportedLanguageError extends TranslationError {
  final String languageCode;
  const UnsupportedLanguageError(this.languageCode, {super.engineId})
      : super('Language $languageCode is not supported by engine $engineId');
}

class ProviderError extends TranslationError {
  final int? statusCode;
  const ProviderError(super.message, {this.statusCode, super.engineId, super.cause});
}

class ParsingError extends TranslationError {
  const ParsingError(super.message, {super.engineId, super.cause});
}

class CancelledError extends TranslationError {
  const CancelledError({super.engineId}) : super('Translation operation was cancelled');
}
