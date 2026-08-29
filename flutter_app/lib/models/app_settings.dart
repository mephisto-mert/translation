import 'package:flutter/foundation.dart';

@immutable
class AppSettings {
  final int settingsVersion;
  final String sourceLanguage;
  final String targetLanguage;
  final String primaryEngine; // 'auto', 'gemini', 'deepl', 'google', 'mymemory'
  final bool enableInputMode;
  final bool enableBubbleMode;
  final bool enableClipboardMode;
  final List<int> chatKeys;
  final Set<String> triggerChars;
  final bool enableGlossary;
  final Map<String, String> customGlossaryTerms;
  final bool enableAutoPunctuation;
  final bool enableHistory;
  final int maxHistoryItems;
  final bool enablePersistentCache;
  final int maxCacheEntries;
  final String uiLanguage;

  const AppSettings({
    this.settingsVersion = 2,
    this.sourceLanguage = 'tr',
    this.targetLanguage = 'en',
    this.primaryEngine = 'auto',
    this.enableInputMode = true,
    this.enableBubbleMode = true,
    this.enableClipboardMode = true,
    this.chatKeys = const [89, 85, 13], // Y, U, Enter
    this.triggerChars = const {'.', '!', '?', ','},
    this.enableGlossary = true,
    this.customGlossaryTerms = const {},
    this.enableAutoPunctuation = true,
    this.enableHistory = true,
    this.maxHistoryItems = 50,
    this.enablePersistentCache = true,
    this.maxCacheEntries = 500,
    this.uiLanguage = 'tr',
  });

  AppSettings copyWith({
    int? settingsVersion,
    String? sourceLanguage,
    String? targetLanguage,
    String? primaryEngine,
    bool? enableInputMode,
    bool? enableBubbleMode,
    bool? enableClipboardMode,
    List<int>? chatKeys,
    Set<String>? triggerChars,
    bool? enableGlossary,
    Map<String, String>? customGlossaryTerms,
    bool? enableAutoPunctuation,
    bool? enableHistory,
    int? maxHistoryItems,
    bool? enablePersistentCache,
    int? maxCacheEntries,
    String? uiLanguage,
  }) {
    return AppSettings(
      settingsVersion: settingsVersion ?? this.settingsVersion,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      primaryEngine: primaryEngine ?? this.primaryEngine,
      enableInputMode: enableInputMode ?? this.enableInputMode,
      enableBubbleMode: enableBubbleMode ?? this.enableBubbleMode,
      enableClipboardMode: enableClipboardMode ?? this.enableClipboardMode,
      chatKeys: chatKeys ?? this.chatKeys,
      triggerChars: triggerChars ?? this.triggerChars,
      enableGlossary: enableGlossary ?? this.enableGlossary,
      customGlossaryTerms: customGlossaryTerms ?? this.customGlossaryTerms,
      enableAutoPunctuation: enableAutoPunctuation ?? this.enableAutoPunctuation,
      enableHistory: enableHistory ?? this.enableHistory,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      enablePersistentCache: enablePersistentCache ?? this.enablePersistentCache,
      maxCacheEntries: maxCacheEntries ?? this.maxCacheEntries,
      uiLanguage: uiLanguage ?? this.uiLanguage,
    );
  }

  Map<String, dynamic> toJson() => {
        'settingsVersion': settingsVersion,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'primaryEngine': primaryEngine,
        'enableInputMode': enableInputMode,
        'enableBubbleMode': enableBubbleMode,
        'enableClipboardMode': enableClipboardMode,
        'chatKeys': chatKeys,
        'triggerChars': triggerChars.toList(),
        'enableGlossary': enableGlossary,
        'customGlossaryTerms': customGlossaryTerms,
        'enableAutoPunctuation': enableAutoPunctuation,
        'enableHistory': enableHistory,
        'maxHistoryItems': maxHistoryItems,
        'enablePersistentCache': enablePersistentCache,
        'maxCacheEntries': maxCacheEntries,
        'uiLanguage': uiLanguage,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    Map<String, String> customGlossary = {};
    if (json['customGlossaryTerms'] != null) {
      customGlossary = Map<String, String>.from(json['customGlossaryTerms'] as Map);
    }

    return AppSettings(
      settingsVersion: 2,
      sourceLanguage: json['sourceLanguage'] as String? ?? 'tr',
      targetLanguage: json['targetLanguage'] as String? ?? 'en',
      primaryEngine: json['primaryEngine'] as String? ?? 'auto',
      enableInputMode: json['enableInputMode'] as bool? ?? true,
      enableBubbleMode: json['enableBubbleMode'] as bool? ?? true,
      enableClipboardMode: json['enableClipboardMode'] as bool? ?? true,
      chatKeys: json['chatKeys'] != null ? List<int>.from(json['chatKeys'] as List) : const [89, 85, 13],
      triggerChars: json['triggerChars'] != null
          ? Set<String>.from(json['triggerChars'] as List)
          : const {'.', '!', '?', ','},
      enableGlossary: json['enableGlossary'] as bool? ?? true,
      customGlossaryTerms: customGlossary,
      enableAutoPunctuation: json['enableAutoPunctuation'] as bool? ?? true,
      enableHistory: json['enableHistory'] as bool? ?? true,
      maxHistoryItems: json['maxHistoryItems'] as int? ?? 50,
      enablePersistentCache: json['enablePersistentCache'] as bool? ?? true,
      maxCacheEntries: json['maxCacheEntries'] as int? ?? 500,
      uiLanguage: json['uiLanguage'] as String? ?? 'tr',
    );
  }
}
