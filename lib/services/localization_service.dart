import 'package:flutter/material.dart';

class L10n extends ChangeNotifier {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'completed': 'All prayers completed today',
      'loc_disabled': '⚠️ Location service is disabled',
      'loc_denied': '⚠️ Location permission denied',
      'loc_error': '❌ Failed to get location',
      'prayer_error': '❌ Failed to calculate prayer times',
      'fallback': '📡 Showing cached times (offline)',
    },
    'ar': {
      'fajr': 'الفجر',
      'sunrise': 'الشروق',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'completed': 'انتهت صلوات اليوم',
      'loc_disabled': '⚠️ خدمة الموقع غير مفعلة',
      'loc_denied': '⚠️ تم رفض إذن الموقع',
      'loc_error': '❌ فشل في تحديد الموقع',
      'prayer_error': '❌ فشل في حساب أوقات الصلاة',
      'fallback': '📡 عرض أوقات محفوظة (بدون إنترنت)',
    },
  };

  static const List<String> supportedLocales = ['en', 'ar'];
  static const String defaultLocale = 'ar';

  String _locale = defaultLocale;
  String get locale => _locale;

  // Optional: expose Locale object for MaterialApp
  Locale get currentLocale => Locale(_locale);

  L10n({String? locale}) {
    if (locale != null && supportedLocales.contains(locale)) {
      _locale = locale;
    }
  }

  /// Translate a key
  String t(String key) =>
      _translations[_locale]?[key] ?? _translations[defaultLocale]?[key] ?? key;

  /// Alias for cleaner syntax: context.l10n.t('key')
  String call(String key) => t(key);

  /// Time format pattern based on locale
  String timePattern() => _locale.startsWith('ar') ? 'HH:mm' : 'h:mm a';

  /// Change locale at runtime
  Future<void> setLocale(String newLocale) async {
    if (!supportedLocales.contains(newLocale)) return;
    if (_locale == newLocale) return;

    _locale = newLocale;

    // Optional: persist preference
    // await SharedPreferences.getInstance().then((prefs) => prefs.setString('locale', newLocale));

    notifyListeners(); // Triggers rebuilds where L10n is watched
  }

  /// Get text direction for RTL/LTR support
  TextDirection get textDirection =>
      _locale.startsWith('ar') ? TextDirection.rtl : TextDirection.ltr;
}
