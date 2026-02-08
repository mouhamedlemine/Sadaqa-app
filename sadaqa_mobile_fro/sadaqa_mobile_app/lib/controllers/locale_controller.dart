import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _key = "app_locale"; // ar / fr / en

  Locale _locale = const Locale('fr'); // الافتراضي FR
  Locale get locale => _locale;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);

    if (code == 'ar') {
      _locale = const Locale('ar');
    } else if (code == 'en') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('fr');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> toggleArFr() async {
    if (_locale.languageCode == 'ar') {
      await setLocale(const Locale('fr'));
    } else {
      await setLocale(const Locale('ar'));
    }
  }
}
