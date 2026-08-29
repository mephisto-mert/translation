import 'package:flutter/foundation.dart';
import '../models/translation_result.dart';
import '../services/translation_history_service.dart';

class HistoryController extends ChangeNotifier {
  final TranslationHistoryService _historyService = TranslationHistoryService();

  List<TranslationHistoryItem> get items => _historyService.history;

  HistoryController() {
    _initHistory();
  }

  Future<void> _initHistory() async {
    await _historyService.init();
    notifyListeners();
  }

  Future<void> addHistory(TranslationResult result) async {
    await _historyService.addHistory(
      originalText: result.originalText,
      translatedText: result.translatedText,
      sourceLang: result.sourceLanguage,
      targetLang: result.targetLanguage,
      engine: result.engine,
    );
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    await _historyService.removeItem(id);
    notifyListeners();
  }
}
