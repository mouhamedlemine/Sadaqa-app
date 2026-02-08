import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access_token");
  return token != null && token.isNotEmpty;
}

Future<void> openFavorites(BuildContext context) async {
  final logged = await isLoggedIn();

  if (!logged) {
    final goLogin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تسجيل الدخول مطلوب"),
        content: const Text("لا يمكنك عرض المفضلة إلا بعد تسجيل الدخول."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("تسجيل الدخول"),
          ),
        ],
      ),
    );

    if (goLogin == true) {
      if (!context.mounted) return;
      Navigator.pushNamed(context, "/login");
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.pushNamed(context, "/favorites");
}
