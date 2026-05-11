import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._privateConstructor();

  static final SettingsService instance = SettingsService._privateConstructor();

  bool _initialized = false;
  SharedPreferences? _prefs;

  // ---------------------------------------------------------------------------
  // Prayer Notification Toggles (Persisted)
  // ---------------------------------------------------------------------------
  bool _fajrEnabled = true;
  bool _dhuhrEnabled = true;
  bool _asrEnabled = true;
  bool _maghribEnabled = true;
  bool _ishaEnabled = true;
  bool _sunriseEnabled = false; // Optional: some users want sunrise reminder

  bool get fajrEnabled => _fajrEnabled;
  bool get dhuhrEnabled => _dhuhrEnabled;
  bool get asrEnabled => _asrEnabled;
  bool get maghribEnabled => _maghribEnabled;
  bool get ishaEnabled => _ishaEnabled;
  bool get sunriseEnabled => _sunriseEnabled;

  // ---------------------------------------------------------------------------
  // General Notification Settings
  // ---------------------------------------------------------------------------
  bool _preAlertsEnabled = true; // Notify 10 min before prayer
  bool _onlyNextPrayer = false; // Only notify for next upcoming prayer
  int _preAlertMinutes = 10; // Minutes before prayer for pre-alert

  bool get preAlertsEnabled => _preAlertsEnabled;
  bool get onlyNextPrayer => _onlyNextPrayer;
  int get preAlertMinutes => _preAlertMinutes;

  // ---------------------------------------------------------------------------
  // Calculation Settings (Persisted)
  // ---------------------------------------------------------------------------
  CalculationMethod _calculationMethod = CalculationMethod.egyptian;
  Madhab _madhab = Madhab.shafi;
  String _timezone = 'auto'; // or specific IANA timezone

  CalculationMethod get calculationMethod => _calculationMethod;
  Madhab get madhab => _madhab;
  String get timezone => _timezone;

  // ---------------------------------------------------------------------------
  // UI/UX Settings
  // ---------------------------------------------------------------------------
  bool _hijriDateEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  String _notificationSound = 'Minshawi';

  bool get hijriDateEnabled => _hijriDateEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get soundEnabled => _soundEnabled;
  String get notificationSound => _notificationSound;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    // Prayer toggles
    _fajrEnabled = _prefs!.getBool('fajr_enabled') ?? true;
    _dhuhrEnabled = _prefs!.getBool('dhuhr_enabled') ?? true;
    _asrEnabled = _prefs!.getBool('asr_enabled') ?? true;
    _maghribEnabled = _prefs!.getBool('maghrib_enabled') ?? true;
    _ishaEnabled = _prefs!.getBool('isha_enabled') ?? true;
    _sunriseEnabled = _prefs!.getBool('sunrise_enabled') ?? false;

    // Notification behavior
    _preAlertsEnabled = _prefs!.getBool('pre_alerts') ?? true;
    _onlyNextPrayer = _prefs!.getBool('only_next_prayer') ?? false;
    _preAlertMinutes = _prefs!.getInt('pre_alert_minutes') ?? 10;

    // Calculation settings
    final methodIndex =
        _prefs!.getInt('calc_method') ?? CalculationMethod.egyptian.index;
    _calculationMethod = CalculationMethod.values[methodIndex];

    final madhabIndex = _prefs!.getInt('madhab') ?? Madhab.shafi.index;
    _madhab = Madhab.values[madhabIndex];

    _timezone = _prefs!.getString('timezone') ?? 'auto';

    // UI settings
    _hijriDateEnabled = _prefs!.getBool('hijri_enabled') ?? true;
    _vibrationEnabled = _prefs!.getBool('vibration_enabled') ?? true;
    _soundEnabled = _prefs!.getBool('sound_enabled') ?? true;
    _notificationSound = _prefs!.getString('notification_sound') ?? 'default';
  }

  // ---------------------------------------------------------------------------
  // Save Methods (Private - called by setters)
  // ---------------------------------------------------------------------------
  Future<void> _saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  // ---------------------------------------------------------------------------
  // Public Setters with Persistence + Notify
  // ---------------------------------------------------------------------------

  // Prayer toggles
  Future<void> setPrayerEnabled(Prayer prayer, bool enabled) async {
    switch (prayer) {
      case Prayer.fajr:
        _fajrEnabled = enabled;
        await _saveBool('fajr_enabled', enabled);
        break;
      case Prayer.dhuhr:
        _dhuhrEnabled = enabled;
        await _saveBool('dhuhr_enabled', enabled);
        break;
      case Prayer.asr:
        _asrEnabled = enabled;
        await _saveBool('asr_enabled', enabled);
        break;
      case Prayer.maghrib:
        _maghribEnabled = enabled;
        await _saveBool('maghrib_enabled', enabled);
        break;
      case Prayer.isha:
        _ishaEnabled = enabled;
        await _saveBool('isha_enabled', enabled);
        break;
      case Prayer.sunrise:
        _sunriseEnabled = enabled;
        await _saveBool('sunrise_enabled', enabled);
        break;
      default:
        return;
    }
    notifyListeners();
  }

  // Bulk toggle all prayers
  Future<void> setAllPrayersEnabled(bool enabled) async {
    _fajrEnabled = enabled;
    _dhuhrEnabled = enabled;
    _asrEnabled = enabled;
    _maghribEnabled = enabled;
    _ishaEnabled = enabled;
    _sunriseEnabled = enabled;

    await Future.wait([
      _saveBool('fajr_enabled', enabled),
      _saveBool('dhuhr_enabled', enabled),
      _saveBool('asr_enabled', enabled),
      _saveBool('maghrib_enabled', enabled),
      _saveBool('isha_enabled', enabled),
      _saveBool('sunrise_enabled', enabled),
    ]);
    notifyListeners();
  }

  // Notification behavior
  Future<void> setPreAlertsEnabled(bool enabled) async {
    _preAlertsEnabled = enabled;
    await _saveBool('pre_alerts', enabled);
    notifyListeners();
  }

  Future<void> setOnlyNextPrayer(bool onlyNext) async {
    _onlyNextPrayer = onlyNext;
    await _saveBool('only_next_prayer', onlyNext);
    notifyListeners();
  }

  Future<void> setPreAlertMinutes(int minutes) async {
    if (minutes < 0 || minutes > 60) return;
    _preAlertMinutes = minutes;
    await _saveInt('pre_alert_minutes', minutes);
    notifyListeners();
  }

  // Calculation settings
  Future<void> setCalculationMethod(CalculationMethod method) async {
    _calculationMethod = method;
    await _saveInt('calc_method', method.index);
    notifyListeners();
  }

  Future<void> setMadhab(Madhab madhab) async {
    _madhab = madhab;
    await _saveInt('madhab', madhab.index);
    notifyListeners();
  }

  Future<void> setTimezone(String timezone) async {
    _timezone = timezone;
    await _saveString('timezone', timezone);
    notifyListeners();
  }

  // UI settings
  Future<void> setHijriDateEnabled(bool enabled) async {
    _hijriDateEnabled = enabled;
    await _saveBool('hijri_enabled', enabled);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveBool('vibration_enabled', enabled);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveBool('sound_enabled', enabled);
    notifyListeners();
  }

  Future<void> setNotificationSound(String sound) async {
    _notificationSound = sound;
    await _saveString('notification_sound', sound);
    notifyListeners();
  }

  bool shouldNotifyForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return _fajrEnabled;
      case Prayer.sunrise:
        return _sunriseEnabled;
      case Prayer.dhuhr:
        return _dhuhrEnabled;
      case Prayer.asr:
        return _asrEnabled;
      case Prayer.maghrib:
        return _maghribEnabled;
      case Prayer.isha:
        return _ishaEnabled;
      default:
        return false;
    }
  }

  Future<void> resetToDefaults() async {
    _fajrEnabled = true;
    _dhuhrEnabled = true;
    _asrEnabled = true;
    _maghribEnabled = true;
    _ishaEnabled = true;
    _sunriseEnabled = false;

    _preAlertsEnabled = true;
    _onlyNextPrayer = false;
    _preAlertMinutes = 10;

    _calculationMethod = CalculationMethod.egyptian;
    _madhab = Madhab.shafi;
    _timezone = 'auto';

    _hijriDateEnabled = true;
    _vibrationEnabled = true;
    _soundEnabled = true;
    _notificationSound = 'default';

    await _prefs?.clear();

    notifyListeners();
  }
}
