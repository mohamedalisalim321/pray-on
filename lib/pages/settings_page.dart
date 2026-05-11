// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pray_on/themes/theme_provider.dart';

import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';

import '../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    return Consumer<SettingsService>(
      builder: (context, settings, _) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader("المنظر"),

          SwitchListTile(
            title: const Text("Dark Mode"),
            value: themeProv.isDarkMode,
            onChanged: (value) async {
              themeProv.toggleTheme();
            },
            secondary: const Icon(Icons.dark_mode_rounded),
          ),

          // ─────────────────────────────────────────────────────────────
          // 🕌 Prayer Notifications Section
          // ─────────────────────────────────────────────────────────────
          // _buildSectionHeader('تنبيهات الصلاة'),

          // // Bulk toggle all prayers
          // _buildBulkToggleTile(context, settings),

          // const Divider(height: 1),

          // // Individual prayer toggles
          // ...Prayer.values.where((p) => p != Prayer.none).map((prayer) {
          //   return _buildPrayerToggleTile(
          //     context,
          //     settings,
          //     prayer,
          //   );
          // }),

          // ─────────────────────────────────────────────────────────────
          // 🔔 Notification Behavior Section
          // ─────────────────────────────────────────────────────────────
          _buildSectionHeader('سلوك التنبيهات'),

          SwitchListTile(
            title: const Text('تنبيه مسبق'),
            subtitle: const Text('إشعار قبل وقت الصلاة'),
            value: settings.preAlertsEnabled,
            onChanged: (enabled) async {
              await settings.setPreAlertsEnabled(enabled);
              await _rescheduleNotifications(context, settings);
            },
            secondary: const Icon(Icons.notifications_active_outlined),
          ),

          if (settings.preAlertsEnabled)
            ListTile(
              title: const Text('مدة التنبيه المسبق'),
              subtitle: Text('${settings.preAlertMinutes} دقائق قبل الصلاة'),
              trailing: DropdownButton<int>(
                value: settings.preAlertMinutes,
                items: [5, 10, 15, 20, 30]
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m دقائق'),
                        ))
                    .toList(),
                onChanged: (minutes) async {
                  if (minutes != null) {
                    await settings.setPreAlertMinutes(minutes);
                    await _rescheduleNotifications(context, settings);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('✅ تم تحديث مدة التنبيه إلى $minutes دقائق'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            ),

          SwitchListTile(
            title: const Text('الصلاة القادمة فقط'),
            subtitle: const Text('إشعار للصلاة التالية فقط وتجاهل البقية'),
            value: settings.onlyNextPrayer,
            onChanged: (onlyNext) async {
              await settings.setOnlyNextPrayer(onlyNext);
              await _rescheduleNotifications(context, settings);
            },
            secondary: const Icon(Icons.looks_one),
          ),

          // ─────────────────────────────────────────────────────────────
          // 🧮 Calculation Settings Section
          // ─────────────────────────────────────────────────────────────
          _buildSectionHeader('حساب مواقيت الصلاة'),

          ListTile(
            title: const Text('طريقة الحساب'),
            subtitle: Text(
                _getCalculationMethodDisplayName(settings.calculationMethod)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCalculationMethodDialog(context, settings),
            leading: const Icon(Icons.calculate_outlined),
          ),

          ListTile(
            title: const Text('المذهب (لحساب وقت العصر)'),
            subtitle: Text(_getMadhabDisplayName(settings.madhab)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showMadhabDialog(context, settings),
            leading: const Icon(Icons.account_balance_outlined),
          ),

          // Timezone (advanced - hide if using 'auto')
          // ListTile(
          //   title: const Text('المنطقة الزمنية'),
          //   subtitle: Text(settings.timezone == 'auto' ? 'تلقائي (جهاز)' : settings.timezone),
          //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          //   onTap: () => _showTimezoneDialog(context, settings),
          //   leading: const Icon(Icons.public),
          // ),

          // ─────────────────────────────────────────────────────────────
          // 🎨 UI & Experience Section
          // ─────────────────────────────────────────────────────────────
          _buildSectionHeader('واجهة المستخدم'),

          SwitchListTile(
            title: const Text('عرض التاريخ الهجري'),
            subtitle: const Text('إظهار التاريخ الهجري بجانب الميلادي'),
            value: settings.hijriDateEnabled,
            onChanged: settings.setHijriDateEnabled,
            secondary: const Icon(Icons.calendar_today_outlined),
          ),

          SwitchListTile(
            title: const Text('اهتزاز عند التنبيه'),
            value: settings.vibrationEnabled,
            onChanged: settings.setVibrationEnabled,
            secondary: const Icon(Icons.vibration),
          ),

          SwitchListTile(
            title: const Text('صوت التنبيه'),
            value: settings.soundEnabled,
            onChanged: settings.setSoundEnabled,
            secondary: const Icon(Icons.volume_up_outlined),
          ),

          if (settings.soundEnabled)
            ListTile(
              title: const Text('نغمة التنبيه'),
              subtitle: Text(_getSoundDisplayName(settings.notificationSound)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showSoundDialog(context, settings),
              leading: const Icon(Icons.music_note_outlined),
            ),

          // ─────────────────────────────────────────────────────────────
          // ℹ️ About / Info Section
          // ─────────────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Center(
            child: Text(
              'PrayOn v1.0.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Widget Builders
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBulkToggleTile(BuildContext context, SettingsService settings) {
    final allEnabled = settings.fajrEnabled &&
        settings.dhuhrEnabled &&
        settings.asrEnabled &&
        settings.maghribEnabled &&
        settings.ishaEnabled;

    return SwitchListTile(
      title: const Text('تفعيل/إلغاء الكل'),
      subtitle:
          Text(allEnabled ? 'جميع التنبيهات مفعلة' : 'بعض التنبيهات معطلة'),
      value: allEnabled,
      onChanged: (enabled) async {
        await settings.setAllPrayersEnabled(enabled);
        await _rescheduleNotifications(context, settings);
      },
      secondary: const Icon(Icons.select_all_outlined),
    );
  }

  Widget _buildPrayerToggleTile(
    BuildContext context,
    SettingsService settings,
    Prayer prayer,
  ) {
    final prayerName = _getPrayerDisplayName(prayer);
    final isEnabled = settings.shouldNotifyForPrayer(prayer);

    return SwitchListTile(
      title: Text(prayerName),
      value: isEnabled,
      onChanged: (enabled) async {
        await settings.setPrayerEnabled(prayer, enabled);
        await _rescheduleNotifications(context, settings);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(enabled
                  ? '✅ تم تفعيل تنبيه $prayerName'
                  : '🔕 تم إيقاف تنبيه $prayerName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      secondary: Icon(_getPrayerIcon(prayer), color: _getPrayerColor(prayer)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Dialogs
  // ─────────────────────────────────────────────────────────────────────

  void _showCalculationMethodDialog(
    BuildContext context,
    SettingsService settings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('طريقة الحساب'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: CalculationMethod.values.map((method) {
              return RadioListTile<CalculationMethod>(
                title: Text(_getCalculationMethodDisplayName(method)),
                subtitle: Text(_getCalculationMethodDescription(method),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                value: method,
                groupValue: settings.calculationMethod,
                onChanged: (value) async {
                  if (value != null) {
                    await settings.setCalculationMethod(value);
                    await _rescheduleNotifications(context, settings);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showMadhabDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('المذهب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Madhab.values.map((madhab) {
            return RadioListTile<Madhab>(
              title: Text(_getMadhabDisplayName(madhab)),
              value: madhab,
              groupValue: settings.madhab,
              onChanged: (value) async {
                if (value != null) {
                  await settings.setMadhab(value);
                  await _rescheduleNotifications(context, settings);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showSoundDialog(BuildContext context, SettingsService settings) {
    final sounds = {
      'default': 'النغمة الافتراضية',
      'soft_adhan': 'أذان هادئ',
      'classic_adhan': 'أذان تقليدي',
      'silent': 'صامت (اهتزاز فقط)',
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نغمة التنبيه'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sounds.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: settings.notificationSound,
              onChanged: (value) async {
                if (value != null) {
                  await settings.setNotificationSound(value);
                  await _rescheduleNotifications(context, settings);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة الإعدادات الافتراضية؟'),
        content: const Text(
            'سيتم إعادة جميع الإعدادات إلى قيمها الأصلية. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final settings =
                  Provider.of<SettingsService>(context, listen: false);

              await settings.resetToDefaults();

              await _rescheduleNotifications(context, settings);

              if (ctx.mounted) {
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم استعادة الإعدادات الافتراضية'),
                  ),
                );
              }
            },
            child: const Text('نعم، استعادة'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _rescheduleNotifications(
    BuildContext context,
    SettingsService settings,
  ) async {
    try {
      // TODO:
      // Get prayers from PrayerService or ViewModel
      // Example:
      //
      // final prayers =
      //     context.read<PrayerProvider>().todayPrayers;
      //
      // await NotiService.instance.schedulePrayerNotifications(prayers);

      debugPrint('🔄 Notifications rescheduled');
    } catch (e) {
      debugPrint('❌ Failed to reschedule notifications: $e');
    }
  }

  String _getPrayerDisplayName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return prayer.name;
    }
  }

  IconData _getPrayerIcon(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.brightness_2;
      case Prayer.sunrise:
        return Icons.wb_sunny_outlined;
      case Prayer.dhuhr:
        return Icons.wb_sunny;
      case Prayer.asr:
        return Icons.sunny;
      case Prayer.maghrib:
        return Icons.nightlight_round;
      case Prayer.isha:
        return Icons.brightness_3;
      default:
        return Icons.access_time;
    }
  }

  Color _getPrayerColor(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return const Color(0xFF5E35B1);
      case Prayer.sunrise:
        return const Color(0xFFFF6F00);
      case Prayer.dhuhr:
        return const Color(0xFF1565C0);
      case Prayer.asr:
        return const Color(0xFFF57C00);
      case Prayer.maghrib:
        return const Color(0xFFAD1457);
      case Prayer.isha:
        return const Color(0xFF283593);
      default:
        return Colors.grey;
    }
  }

  String _getCalculationMethodDisplayName(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.muslim_world_league:
        return 'رابطة العالم الإسلامي';
      case CalculationMethod.egyptian:
        return 'الهيئة المصرية العامة للمساحة';
      case CalculationMethod.karachi:
        return 'جامعة العلوم الإسلامية كراتشي';
      // case CalculationMethod.makkah: return 'أم القرى - مكة المكرمة';
      case CalculationMethod.tehran:
        return 'معهد الجيوفيزياء - طهران';
      // case CalculationMethod.isna: return 'الجمعية الإسلامية لأمريكا الشمالية';
      case CalculationMethod.dubai:
        return 'دبي';
      case CalculationMethod.qatar:
        return 'قطر';
      case CalculationMethod.kuwait:
        return 'الكويت';
      case CalculationMethod.turkey:
        return 'تركيا';
      case CalculationMethod.singapore:
        return 'سنغافورة';
      // case CalculationMethod.france: return 'اتحاد منظمات إسلامية في فرنسا';
      // case CalculationMethod.morocco: return 'المغرب';
      // case CalculationMethod.jordan: return 'الأردن';
      case CalculationMethod.other:
        return 'أخرى (مخصصة)';
      default:
        return method.name;
    }
  }

  String _getCalculationMethodDescription(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.egyptian:
        return 'الأكثر استخداماً في مصر والسودان';
      // case CalculationMethod.makkah: return 'المعتمدة في المملكة العربية السعودية';
      case CalculationMethod.muslim_world_league:
        return 'معتمدة في معظم الدول الإسلامية';
      case CalculationMethod.karachi:
        return 'معتمدة في باكستان والهند';
      default:
        return 'طريقة حساب قياسية';
    }
  }

  String _getMadhabDisplayName(Madhab madhab) {
    switch (madhab) {
      case Madhab.shafi:
        return 'الشافعي (معظم الدول)';
      case Madhab.hanafi:
        return 'الحنفي (تركيا، جنوب آسيا)';
      default:
        return madhab.name;
    }
  }

  String _getSoundDisplayName(String sound) {
    switch (sound) {
      case 'default':
        return 'النغمة الافتراضية';
      case 'soft_adhan':
        return 'أذان هادئ';
      case 'classic_adhan':
        return 'أذان تقليدي';
      case 'silent':
        return 'صامت';
      default:
        return sound;
    }
  }
}
