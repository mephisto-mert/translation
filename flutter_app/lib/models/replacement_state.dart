/// Formal replacement state machine for Input Mode text replacement
enum ReplacementState {
  idle,
  collectingInput,
  translationPending,
  translating,
  translationReady,
  validatingTargetWindow,
  replacing,
  completed,
  cancelled,
  failed,
}

class ReplacementContext {
  final ReplacementState state;
  final String originalInput;
  final int targetHwnd;
  final String? targetProcessName;
  final int extraCharsTypedDuringTranslation;
  final String? translatedResult;
  final String? errorMessage;
  final DateTime startTime;

  ReplacementContext({
    this.state = ReplacementState.idle,
    this.originalInput = '',
    this.targetHwnd = 0,
    this.targetProcessName,
    this.extraCharsTypedDuringTranslation = 0,
    this.translatedResult,
    this.errorMessage,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  ReplacementContext copyWith({
    ReplacementState? state,
    String? originalInput,
    int? targetHwnd,
    String? targetProcessName,
    int? extraCharsTypedDuringTranslation,
    String? translatedResult,
    String? errorMessage,
  }) {
    return ReplacementContext(
      state: state ?? this.state,
      originalInput: originalInput ?? this.originalInput,
      targetHwnd: targetHwnd ?? this.targetHwnd,
      targetProcessName: targetProcessName ?? this.targetProcessName,
      extraCharsTypedDuringTranslation:
          extraCharsTypedDuringTranslation ?? this.extraCharsTypedDuringTranslation,
      translatedResult: translatedResult ?? this.translatedResult,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime,
    );
  }
}
