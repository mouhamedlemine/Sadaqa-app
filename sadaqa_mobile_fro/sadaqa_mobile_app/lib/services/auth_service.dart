// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Social login
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../config/api_config.dart';

class AuthService {
  // ✅ مطابق لمسارات Django عندك لأنك عامل:
  // path("api/auth/", include("accounts.urls"))
  static const String _registerPath = '/api/auth/register/';
  static const String _loginPath = '/api/auth/login/';
  static const String _mePath = '/api/auth/me/';
  static const String _tokenRefreshPath = '/api/auth/token/refresh/';
  static const String _googleLoginPath = '/api/auth/google-login/';

  // ⚠️ Facebook endpoint غير موجود في views.py التي أرسلتها
  // إذا أضفت في Django: path("facebook-login/", FacebookLoginView.as_view())
  // فعِّله هنا:
  static const String? _facebookLoginPath = null; // مثال: '/api/auth/facebook-login/';

  // Google Sign-In
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '1074890326132-d53a2f96h67lr7l31ph7eq3k06h7u4ko.apps.googleusercontent.com',
    scopes: <String>['email', 'profile', 'openid'],
  );

  // -------------------------
  // ✅ Register
  // POST /api/auth/register/
  // -------------------------
  Future<String?> register({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_registerPath');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
        }),
      );

      if (response.statusCode == 201) return null;
      return _extractErrorMessage(response);
    } catch (e) {
      return 'Erreur réseau: $e';
    }
  }

  // -------------------------
  // ✅ Login (email / password)
  // POST /api/auth/login/
  // -------------------------
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_loginPath');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;

        if (accessToken == null || refreshToken == null) {
          return 'لم يرسل الخادم رموز الدخول بشكل صحيح.';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        return null;
      }

      return _extractErrorMessage(response);
    } catch (e) {
      return 'Erreur réseau: $e';
    }
  }

  // -------------------------
  // ✅ Refresh Access Token
  // POST /api/auth/token/refresh/
  // -------------------------
  Future<bool> refreshAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');
      if (refresh == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}$_tokenRefreshPath');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['access'] as String?;
        if (newAccess == null) return false;

        await prefs.setString('access_token', newAccess);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------
  // ✅ Google Login
  // POST /api/auth/google-login/
  // -------------------------
  Future<String?> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return 'تم إلغاء العملية من قبل المستخدم.';
      }

      final googleAuth = await account.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessTokenGoogle = googleAuth.accessToken;

      if (idToken == null && accessTokenGoogle == null) {
        return 'تعذر الحصول على بيانات التوثيق من Google.';
      }

      final payload = <String, dynamic>{};
      if (idToken != null) payload['id_token'] = idToken;
      if (accessTokenGoogle != null) payload['access_token'] = accessTokenGoogle;

      final url = Uri.parse('${ApiConfig.baseUrl}$_googleLoginPath');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;

        if (accessToken == null || refreshToken == null) {
          return 'لم يرسل الخادم رموز الدخول بشكل صحيح.';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        return null;
      }

      return _extractErrorMessage(response);
    } catch (e) {
      return 'فشل تسجيل الدخول عبر Google: $e';
    }
  }

  // -------------------------
  // ✅ Facebook Login (Mobile)
  // -------------------------
  Future<String?> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email'],
      );

      if (result.status == LoginStatus.cancelled) {
        return 'تم إلغاء العملية من قبل المستخدم.';
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        return 'فشل تسجيل الدخول عبر Facebook: ${result.message ?? ''}';
      }

      final fbToken = result.accessToken!.tokenString;

      // إذا ما عندك endpoint في Django، نوقف هنا
      if (_facebookLoginPath == null) {
        return "تم تسجيل الدخول من Facebook، لكن لا يوجد endpoint في Django لاستقبال التوكن.\n"
            "أضف facebook-login في backend أو عطّل زر Facebook.";
      }

      return await loginWithFacebookToken(fbToken);
    } catch (e) {
      return 'فشل تسجيل الدخول عبر Facebook: $e';
    }
  }

  // -------------------------
  // ✅ Facebook Token Login (Web or Mobile token)
  // -------------------------
  Future<String?> loginWithFacebookToken(String fbToken) async {
    if (_facebookLoginPath == null) {
      return "Facebook backend غير مُفعّل في Django حالياً.";
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$_facebookLoginPath');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': fbToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;

        if (accessToken == null || refreshToken == null) {
          return 'لم يرسل الخادم رموز الدخول بشكل صحيح.';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        return null;
      }

      return _extractErrorMessage(response);
    } catch (e) {
      return 'فشل تسجيل الدخول عبر Facebook (Token): $e';
    }
  }

  // -------------------------
  // ✅ Current user
  // GET /api/auth/me/
  // -------------------------
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$_mePath');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // لو access انتهى -> حاول refresh ثم أعد
      if (response.statusCode == 401) {
        final ok = await refreshAccessToken();
        if (ok) return await getCurrentUser();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // -------------------------
  // ✅ Logout
  // -------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
  }

  // -------------------------
  // ✅ Error helper
  // -------------------------
  String _extractErrorMessage(http.Response response) {
    try {
      final body = response.body;
      if (body.isEmpty) {
        return "تعذر إتمام العملية. كود الخطأ: ${response.statusCode}";
      }

      final data = jsonDecode(body);

      if (data is Map<String, dynamic>) {
        if (data['detail'] != null) return data['detail'].toString();

        final List<String> messages = [];

        data.forEach((key, value) {
          String fieldName;
          switch (key) {
            case 'email':
              fieldName = 'البريد الإلكتروني';
              break;
            case 'username':
              fieldName = 'اسم المستخدم';
              break;
            case 'first_name':
              fieldName = 'الاسم الأول';
              break;
            case 'last_name':
              fieldName = 'اسم العائلة';
              break;
            case 'password':
              fieldName = 'كلمة المرور';
              break;
            default:
              fieldName = key;
          }

          if (value is List && value.isNotEmpty) {
            messages.add('$fieldName: ${value.first}');
          } else {
            messages.add('$fieldName: $value');
          }
        });

        if (messages.isNotEmpty) return messages.join("\n");
      }

      return "تعذر إتمام العملية. كود الخطأ: ${response.statusCode}";
    } catch (_) {
      return "خطأ في الاتصال بالخادم. حاول مرة أخرى.";
    }
  }
}
