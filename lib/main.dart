import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

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

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent system UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Error handling
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

  // ── Timezone ──────────────────────────────────────────────────────────────
  // NOTE: Do NOT call tz.initializeTimeZones() here.
  // NotiService.initialize() already calls tz_data.initializeTimeZones()
  // (which uses latest_all — a superset). Calling it twice wastes startup
  // time and risks importing a different dataset (latest vs latest_all).

  // Theme init
  final themeProv = await ThemeProvider.createInitialized();

  // Services init
  await SettingsService.instance.initialize();

  // NotiService: initialize early so the plugin and timezone are ready before
  // any widget tree asks to schedule. Permissions are requested here too, but
  // the OS dialog will only surface once the first Activity is visible —
  // Flutter handles that automatically on Android.
  await NotiService.instance.initialize();
   await NotiService.instance.showTestNotification();

  runApp(
    MultiProvider(
      providers: [
        // ───────── UI ─────────
        ChangeNotifierProvider(create: (_) => L10n()),

        ChangeNotifierProvider.value(value: themeProv),

        // ───────── CORE STATE ─────────
        ChangeNotifierProvider(create: (_) => SettingsService.instance),

        ChangeNotifierProvider(create: (_) => LocationService()),

        // ───────── DERIVED SERVICES ─────────
        // PrayerService is intentionally NOT rebuilt on every LocationService
        // change; the page calls invalidateCache() manually when it needs a
        // fresh calculation, so we keep a stable instance here.
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
