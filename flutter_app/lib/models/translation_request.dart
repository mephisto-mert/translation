import 'package:flutter/foundation.dart';

/// Immutable model representing a translation request
@immutable
class TranslationRequest {
  final String text;
  final String sourceLanguage;
  final String targetLanguage;
  final String? preferredEngine;
  final bool applyGlossary;
  final bool applyPunctuation;
  final String requestId;
  final DateTime timestamp;

  TranslationRequest({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.preferredEngine,
    this.applyGlossary = true,
    this.applyPunctuation = true,
    String? requestId,
    DateTime? timestamp,
  })  : requestId = requestId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  TranslationRequest copyWith({
    String? text,
    String? sourceLanguage,
    String? targetLanguage,
    String? preferredEngine,
    bool? applyGlossary,
    bool? applyPunctuation,
  }) {
    return TranslationRequest(
      text: text ?? this.text,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      preferredEngine: preferredEngine ?? this.preferredEngine,
      applyGlossary: applyGlossary ?? this.applyGlossary,
      applyPunctuation: applyPunctuation ?? this.applyPunctuation,
      requestId: requestId,
      timestamp: timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationRequest &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          sourceLanguage == other.sourceLanguage &&
          targetLanguage == other.targetLanguage &&
          preferredEngine == other.preferredEngine &&
          applyGlossary == other.applyGlossary &&
          applyPunctuation == other.applyPunctuation;

  @override
  int get hashCode =>
      text.hashCode ^
      sourceLanguage.hashCode ^
      targetLanguage.hashCode ^
      preferredEngine.hashCode ^
      applyGlossary.hashCode ^
      applyPunctuation.hashCode;
}
