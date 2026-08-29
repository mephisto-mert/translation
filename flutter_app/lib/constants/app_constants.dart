/// Uygulama genelinde kullanılan sabit değerler
library;

class AppConstants {
  AppConstants._();

  // Pencere boyutları
  static const double windowWidth = 460;
  static const double windowHeight = 720;
  static const double windowMinWidth = 400;
  static const double windowMinHeight = 600;

  // Tooltip
  static const int tooltipAutoCloseMs = 12000;
  static const double tooltipMinWidth = 400;
  static const double tooltipMaxWidth = 700;
  static const double tooltipMaxHeight = 500;

  // Zamanlayıcılar
  static const Duration statusCheckInterval = Duration(seconds: 15);
  static const Duration translationDebounce = Duration(milliseconds: 300);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimation = Duration(milliseconds: 150);

  // Limitler
  static const int clipboardMaxLength = 100000;
  static const int minSelectedTextLength = 2;
  static const int minClipboardTextLength = 3;
  static const Duration clipboardCheckInterval = Duration(milliseconds: 500);

  // Bayrak boyutu
  static const double flagWidth = 28;
  static const double flagHeight = 20;

  // Varsayılan dil ayarları
  static const String defaultSourceLang = 'auto';
  static const String defaultTargetLang = 'tr';
  static const String defaultUiLang = 'tr';
}
