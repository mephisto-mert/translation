import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/translation_error.dart';
import '../../models/translation_request.dart';
import '../../models/translation_result.dart';
import 'translation_engine.dart';

class TranslationFallbackManager {
  final List<TranslationEngine> _engines;
  final Map<String, DateTime> _engineCooldowns = {};
  final Random _random = Random();

  static const Duration _authCooldown = Duration(minutes: 15);
  static const Duration _rateLimitCooldown = Duration(minutes: 2);
  static const Duration _networkCooldown = Duration(seconds: 30);

  TranslationFallbackManager(this._engines);

  /// Executes translation using preferred engine or falls back through available healthy engines
  Future<TranslationResult> translateWithFallback(TranslationRequest request) async {
    final candidateEngines = _getOrderedCandidateEngines(
      request.preferredEngine,
      request.sourceLanguage,
      request.targetLanguage,
    );

    if (candidateEngines.isEmpty) {
      throw const InvalidRequestError(
        'No translation engine is currently configured, healthy, and supporting the requested language pair.',
      );
    }

    TranslationError? lastError;

    for (final engine in candidateEngines) {
      try {
        debugPrint('[FallbackManager] Attempting translation with engine: ${engine.id}');
        final result = await _executeWithRetry(engine, request);
        return result;
      } on AuthenticationError catch (e) {
        debugPrint('[FallbackManager] Auth error on ${engine.id}: ${e.message}');
        _setEngineCooldown(engine.id, _authCooldown);
        lastError = e;
      } on RateLimitError catch (e) {
        debugPrint('[FallbackManager] Rate limit on ${engine.id}: ${e.message}');
        _setEngineCooldown(engine.id, e.retryAfter ?? _rateLimitCooldown);
        lastError = e;
      } on TimeoutError catch (e) {
        debugPrint('[FallbackManager] Timeout on ${engine.id}');
        _setEngineCooldown(engine.id, _networkCooldown);
        lastError = e;
      } on NetworkError catch (e) {
        debugPrint('[FallbackManager] Network error on ${engine.id}');
        _setEngineCooldown(engine.id, _networkCooldown);
        lastError = e;
      } catch (e) {
        debugPrint('[FallbackManager] Unexpected error on ${engine.id}: $e');
        lastError = ProviderError('Engine ${engine.id} failed', cause: e);
      }
    }

    throw lastError ??
        const ProviderError('All candidate translation engines failed or are in cooldown.');
  }

  Future<TranslationResult> _executeWithRetry(
      TranslationEngine engine, TranslationRequest request) async {
    const int maxAttempts = 2;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await engine.translate(request);
      } on TimeoutError {
        if (attempt == maxAttempts) rethrow;
        await _applyBackoff(attempt);
      } on NetworkError {
        if (attempt == maxAttempts) rethrow;
        await _applyBackoff(attempt);
      } on ProviderError catch (e) {
        if (e.statusCode != null && e.statusCode! >= 500 && attempt < maxAttempts) {
          await _applyBackoff(attempt);
        } else {
          rethrow;
        }
      }
    }

    throw ProviderError('Engine ${engine.id} execution failed after $maxAttempts attempts.');
  }

  Future<void> _applyBackoff(int attempt) async {
    final baseDelayMs = 300 * pow(2, attempt - 1).toInt();
    final jitterMs = _random.nextInt(150);
    await Future.delayed(Duration(milliseconds: baseDelayMs + jitterMs));
  }

  List<TranslationEngine> _getOrderedCandidateEngines(
      String? preferredId, String sourceLang, String targetLang) {
    final result = <TranslationEngine>[];

    bool isEngineValidCandidate(TranslationEngine e) {
      return e.isConfigured &&
          e.supportsLanguage(sourceLang, targetLang) &&
          !_isEngineInCooldown(e.id);
    }

    if (preferredId != null && preferredId != 'auto') {
      final preferred = _engines.firstWhere(
        (e) => e.id == preferredId && isEngineValidCandidate(e),
        orElse: () => _engines.firstWhere(
          (e) => isEngineValidCandidate(e),
          orElse: () => _engines.firstWhere((e) => false, orElse: () => DummyEngine()),
        ),
      );
      if (preferred is! DummyEngine && isEngineValidCandidate(preferred)) {
        result.add(preferred);
      }
    }

    for (final engine in _engines) {
      if (!result.contains(engine) && isEngineValidCandidate(engine)) {
        result.add(engine);
      }
    }

    return result;
  }

  bool _isEngineInCooldown(String engineId) {
    final until = _engineCooldowns[engineId];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _engineCooldowns.remove(engineId);
      return false;
    }
    return true;
  }

  void _setEngineCooldown(String engineId, Duration duration) {
    _engineCooldowns[engineId] = DateTime.now().add(duration);
  }

  void resetCooldowns() {
    _engineCooldowns.clear();
  }
}

class DummyEngine implements TranslationEngine {
  @override
  String get id => 'dummy';
  @override
  String get displayName => 'Dummy';
  @override
  bool get isConfigured => false;
  @override
  bool get requiresApiKey => false;
  @override
  bool supportsLanguage(String sourceLang, String targetLang) => false;
  @override
  Future<TranslationResult> translate(TranslationRequest request) =>
      throw UnimplementedError();
}
