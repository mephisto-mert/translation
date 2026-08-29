import 'package:flutter/foundation.dart';

/// Structured result returned by all translation engines
@immutable
class TranslationResult {
  final String translatedText;
  final String originalText;
  final String sourceLanguage;
  final String targetLanguage;
  final String engine;
  final Duration latency;
  final bool fromCache;
  final DateTime timestamp;

  TranslationResult({
    required this.translatedText,
    required this.originalText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.engine,
    required this.latency,
    this.fromCache = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'translatedText': translatedText,
        'originalText': originalText,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'engine': engine,
        'latencyMs': latency.inMilliseconds,
        'fromCache': fromCache,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TranslationResult.fromJson(Map<String, dynamic> json) => TranslationResult(
        translatedText: json['translatedText'] as String,
        originalText: json['originalText'] as String,
        sourceLanguage: json['sourceLanguage'] as String,
        targetLanguage: json['targetLanguage'] as String,
        engine: json['engine'] as String,
        latency: Duration(milliseconds: json['latencyMs'] as int? ?? 0),
        fromCache: json['fromCache'] as bool? ?? false,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationResult &&
          runtimeType == other.runtimeType &&
          translatedText == other.translatedText &&
          originalText == other.originalText &&
          sourceLanguage == other.sourceLanguage &&
          targetLanguage == other.targetLanguage &&
          engine == other.engine;

  @override
  int get hashCode =>
      translatedText.hashCode ^
      originalText.hashCode ^
      sourceLanguage.hashCode ^
      targetLanguage.hashCode ^
      engine.hashCode;
}
