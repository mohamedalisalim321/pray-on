import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hijri/hijri_calendar.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:provider/provider.dart';

import 'services/adhan_service.dart';
import 'services/localization_service.dart';
import 'services/location_service.dart';
import 'services/noti_service.dart';
import 'services/prayer_service.dart';
import 'services/qibla_service.dart';
import 'services/settings_service.dart';

import 'themes/app_constants.dart';
import 'themes/theme_provider.dart';

import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('❌ Flutter Error: ${details.exception}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('❌ Dart Error: $error');
      debugPrint('Stack: $stack');
    }
    return true;
  };

  // Localization
  await initializeDateFormatting();
  HijriCalendar.setLocal("ar");

  // Theme init
  final themeProv = await ThemeProvider.createInitialized();

  // Services init
  await SettingsService.instance.initialize();

  // 🔥 Initialize background audio service BEFORE runApp
  await JustAudioBackground.init(
    androidNotificationChannelId: 'mohamedali.salim.prayon.channel',
    androidNotificationChannelName: 'Adhan Playback',
    androidNotificationOngoing: true, // Keeps notification persistent
    androidShowNotificationBadge: true, // Show play/pause badge
  );

  await AndroidAlarmManager.initialize();

  await AdhanService.instance.initialize();

  await NotiService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => L10n()),
        ChangeNotifierProvider.value(value: themeProv),
        ChangeNotifierProvider(create: (_) => SettingsService.instance),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ProxyProvider2<LocationService, SettingsService, PrayerService>(
          update: (_, location, settings, previous) =>
              previous ?? PrayerService(),
        ),
        ProxyProvider<LocationService, QiblaService>(
          update: (_, location, previous) => previous ?? QiblaService(),
        ),
      ],
      child: const PrayOn(),
    ),
  );
}

class PrayOn extends StatelessWidget {
  const PrayOn({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final l10n = context.watch<L10n>();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // Locale
          locale: l10n.currentLocale,
          supportedLocales: L10n.supportedLocales.map((lang) => Locale(lang)),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Theme
          theme: theme.themeData,
          themeMode: theme.themeMode,
          themeAnimationDuration: AppConstants.durationNormal,
          themeAnimationCurve: AppConstants.curveDefault,

          // HomePage
          home: const HomePage(),
        );
      },
    );
  }
}
