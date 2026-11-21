import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode.dart';
import 'l10n/language_provider.dart';

class YesSirApp extends StatelessWidget {
  const YesSirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, mode, _) {
            return ValueListenableBuilder<double>(
              valueListenable: fontScaleNotifier,
              builder: (context, fontScale, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: fontScaleChosen,
                  builder: (context, scaleChosen, _) {
                    return MaterialApp.router(
                      title: 'Yes Sir AI',
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.light(),
                      darkTheme: AppTheme.dark(),
                      themeMode: mode,
                      // Settings font size applies app-wide ONLY once the
                      // student picks one; otherwise the device's own
                      // Android font size is respected (a11y).
                      builder: (context, child) => scaleChosen
                          ? MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                textScaler: TextScaler.linear(fontScale),
                              ),
                              child: child!,
                            )
                          : child!,
                      locale: locale,
                      supportedLocales: const [Locale('bn'), Locale('en')],
                      localizationsDelegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      routerConfig: appRouter,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
