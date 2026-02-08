// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';

import 'controllers/locale_controller.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/campaign_list_page.dart';
import 'pages/my_campaigns_page.dart';
import 'pages/favorites_page.dart';
import 'pages/how_it_works_page.dart';
import 'pages/volunteer_page.dart';
import 'pages/about_page.dart'; // ✅ NEW

import 'pages/payment_success_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/reset_password_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeController = LocaleController();
  await localeController.loadSavedLocale();

  runApp(SadaqaApp(localeController: localeController));
}

class SadaqaApp extends StatelessWidget {
  const SadaqaApp({super.key, required this.localeController});

  final LocaleController localeController;

  static const String backendBaseUrl = "http://127.0.0.1:8000";

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (_, __) {
        return MaterialApp(
          title: 'Sadaqa App',
          debugShowCheckedModeBanner: false,

          // Localization
          locale: localeController.locale,
          supportedLocales: const [
            Locale('fr'),
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],

          // RTL للعربية فقط
          builder: (context, child) {
            final lang = Localizations.localeOf(context).languageCode;
            final isAr = lang == 'ar';
            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },

          theme: ThemeData(
            primaryColor: const Color(0xFF6D28D9),
            scaffoldBackgroundColor: const Color(0xFFF7F7FB),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F7FB),
              foregroundColor: Colors.black87,
              elevation: 0,
              centerTitle: true,
            ),
            cardColor: Colors.white,
            shadowColor: Colors.black12,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF6D28D9),
              foregroundColor: Colors.white,
            ),
          ),

          initialRoute: "/",

          onGenerateRoute: (settings) {
            final name = settings.name ?? "/";

            // payment success
            if (name.startsWith("/payment-success")) {
              return MaterialPageRoute(
                builder: (_) =>
                    const PaymentSuccessPage(baseUrl: backendBaseUrl),
                settings: settings,
              );
            }

            if (name == "/forgot-password") {
              return MaterialPageRoute(
                builder: (_) =>
                    const ForgotPasswordPage(baseUrl: backendBaseUrl),
                settings: settings,
              );
            }

            if (name.startsWith("/reset-password")) {
              return MaterialPageRoute(
                builder: (_) => const ResetPasswordPage(),
                settings: settings,
              );
            }

            // ✅ About (من نحن)
            if (name == "/about") {
              return MaterialPageRoute(
                builder: (_) => const AboutPage(),
                settings: settings,
              );
            }

            // Home
            if (name == "/") {
              return MaterialPageRoute(
                builder: (_) => HomePage(localeController: localeController),
                settings: settings,
              );
            }

            // Login
            if (name == "/login") {
              return MaterialPageRoute(
                builder: (_) => const LoginPage(),
                settings: settings,
              );
            }

            // AuthGate
            if (name == "/app") {
              return MaterialPageRoute(
                builder: (_) => const AuthGate(),
                settings: settings,
              );
            }

            // Dashboard
            if (name == "/dashboard") {
              return MaterialPageRoute(
                builder: (_) => const DashboardPage(),
                settings: settings,
              );
            }

            // Campaigns
            if (name == "/campaigns") {
              return MaterialPageRoute(
                builder: (_) => const CampaignListPage(),
                settings: settings,
              );
            }

            // My account / campaigns
            if (name == "/my-campaigns") {
              return MaterialPageRoute(
                builder: (_) => const MyCampaignsPage(),
                settings: settings,
              );
            }

            // Favorites
            if (name == "/favorites") {
              return MaterialPageRoute(
                builder: (_) => const FavoritesPage(),
                settings: settings,
              );
            }

            // How it works
            if (name == "/how-it-works") {
              return MaterialPageRoute(
                builder: (_) => const HowItWorksPage(),
                settings: settings,
              );
            }

            // Volunteer page
            if (name == "/volunteer") {
              return MaterialPageRoute(
                builder: (_) => const VolunteerPage(),
                settings: settings,
              );
            }

            // fallback
            return MaterialPageRoute(
              builder: (_) => HomePage(localeController: localeController),
              settings: settings,
            );
          },
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadToken(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snap.data;
        if (token == null || token.isEmpty) {
          return const LoginPage();
        }

        return const DashboardPage();
      },
    );
  }
}




// lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';

// import 'l10n/app_localizations.dart';
// import 'controllers/locale_controller.dart';

// import 'pages/home_page.dart';
// import 'pages/login_page.dart';
// import 'pages/dashboard_page.dart';
// import 'pages/campaign_list_page.dart';
// import 'pages/my_campaigns_page.dart';
// import 'pages/favorites_page.dart';
// import 'pages/how_it_works_page.dart';
// import 'pages/volunteer_page.dart';

// import 'pages/payment_success_page.dart';
// import 'pages/forgot_password_page.dart';
// import 'pages/reset_password_page.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // ✅ Stripe init (لا تجعل خطأ Stripe يوقف التطبيق)
//   try {
//     Stripe.publishableKey =
//         "pk_test_51So3QsDuZmWSXcFHNCnqpWzMmNvJ09ZSrc0QVpFmpHDmaildKWUb746iSDXoHhAPA8JUzylDOYujPctQ5VuXt7Rq00UwZrBzbV";

//     // (اختياري) سترى الخطأ في console إن حصل
//     await Stripe.instance.applySettings();
//     debugPrint("✅ Stripe initialized successfully");
//   } catch (e) {
//     debugPrint("❌ Stripe init error: $e");
//     // نكمل تشغيل التطبيق حتى لو Stripe فيه مشكلة
//   }

//   final localeController = LocaleController();
//   await localeController.loadSavedLocale();

//   runApp(SadaqaApp(localeController: localeController));
// }

// class SadaqaApp extends StatelessWidget {
//   const SadaqaApp({super.key, required this.localeController});

//   final LocaleController localeController;

//   // ✅ IP الجهاز (ليس 127.0.0.1)
//   static const String backendBaseUrl = "http://192.168.1.131:8000";

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: localeController,
//       builder: (_, __) {
//         return MaterialApp(
//           title: 'Sadaqa App',
//           debugShowCheckedModeBanner: false,

//           // Localization
//           locale: localeController.locale,
//           supportedLocales: const [
//             Locale('fr'),
//             Locale('ar'),
//             Locale('en'),
//           ],
//           localizationsDelegates: const [
//             AppLocalizations.delegate,
//             GlobalMaterialLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//           ],

//           // RTL للعربية فقط
//           builder: (context, child) {
//             final lang = Localizations.localeOf(context).languageCode;
//             final isAr = lang == 'ar';
//             return Directionality(
//               textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
//               child: child ?? const SizedBox.shrink(),
//             );
//           },

//           theme: ThemeData(
//             primaryColor: const Color(0xFF6D28D9),
//             scaffoldBackgroundColor: const Color(0xFFF7F7FB),
//             appBarTheme: const AppBarTheme(
//               backgroundColor: Color(0xFFF7F7FB),
//               foregroundColor: Colors.black87,
//               elevation: 0,
//               centerTitle: true,
//             ),
//             cardColor: Colors.white,
//             shadowColor: Colors.black12,
//             elevatedButtonTheme: ElevatedButtonThemeData(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6D28D9),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 textStyle: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             floatingActionButtonTheme: const FloatingActionButtonThemeData(
//               backgroundColor: Color(0xFF6D28D9),
//               foregroundColor: Colors.white,
//             ),
//           ),

//           initialRoute: "/",

//           onGenerateRoute: (settings) {
//             final name = settings.name ?? "/";

//             if (name.startsWith("/payment-success")) {
//               return MaterialPageRoute(
//                 builder: (_) => const PaymentSuccessPage(baseUrl: backendBaseUrl),
//                 settings: settings,
//               );
//             }

//             if (name == "/forgot-password") {
//               return MaterialPageRoute(
//                 builder: (_) => const ForgotPasswordPage(baseUrl: backendBaseUrl),
//                 settings: settings,
//               );
//             }

//             if (name.startsWith("/reset-password")) {
//               return MaterialPageRoute(
//                 builder: (_) => const ResetPasswordPage(),
//                 settings: settings,
//               );
//             }

//             if (name == "/") {
//               return MaterialPageRoute(
//                 builder: (_) => HomePage(localeController: localeController),
//                 settings: settings,
//               );
//             }

//             if (name == "/login") {
//               return MaterialPageRoute(
//                 builder: (_) => const LoginPage(),
//                 settings: settings,
//               );
//             }

//             if (name == "/app") {
//               return MaterialPageRoute(
//                 builder: (_) => const AuthGate(),
//                 settings: settings,
//               );
//             }

//             if (name == "/dashboard") {
//               return MaterialPageRoute(
//                 builder: (_) => const DashboardPage(),
//                 settings: settings,
//               );
//             }

//             if (name == "/campaigns") {
//               return MaterialPageRoute(
//                 builder: (_) => const CampaignListPage(),
//                 settings: settings,
//               );
//             }

//             if (name == "/my-campaigns") {
//               return MaterialPageRoute(
//                 builder: (_) => const MyCampaignsPage(),
//                 settings: settings,
//               );
//             }

//             if (name == "/favorites") {
//               return MaterialPageRoute(
//                 builder: (_) => const FavoritesPage(),
//                 settings: settings,
//               );
//             }

//             if (name == "/how-it-works") {
//               return MaterialPageRoute(
//                 builder: (_) => const HowItWorksPage(),
//                 settings: settings,
//               );
//             }

//             if (name == "/volunteer") {
//               return MaterialPageRoute(
//                 builder: (_) => const VolunteerPage(),
//                 settings: settings,
//               );
//             }

//             return MaterialPageRoute(
//               builder: (_) => HomePage(localeController: localeController),
//               settings: settings,
//             );
//           },
//         );
//       },
//     );
//   }
// }

// class AuthGate extends StatefulWidget {
//   const AuthGate({super.key});

//   @override
//   State<AuthGate> createState() => _AuthGateState();
// }

// class _AuthGateState extends State<AuthGate> {
//   Future<String?> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString("access_token");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<String?>(
//       future: _loadToken(),
//       builder: (context, snap) {
//         if (snap.connectionState != ConnectionState.done) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         final token = snap.data;
//         if (token == null || token.isEmpty) {
//           return const LoginPage();
//         }

//         return const DashboardPage();
//       },
//     );
//   }
// }
