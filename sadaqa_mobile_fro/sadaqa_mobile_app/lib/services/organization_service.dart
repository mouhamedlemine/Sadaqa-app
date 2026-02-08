import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrganizationService {
  final String baseUrl;
  OrganizationService(this.baseUrl);

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  // ✅ لأن Django عندك: api/register/
  Future<String?> registerOrg({
    required String email,
    required String username,
    required String password,
    required String name,
    String phone = "",
    String address = "",
  }) async {
    final url = Uri.parse('$baseUrl/api/register/');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        "name": name,
        "phone": phone,
        "address": address,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) return null;

    try {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        if (data.containsKey('detail')) return data['detail'].toString();

        final messages = <String>[];
        data.forEach((k, v) {
          if (v is List && v.isNotEmpty) {
            messages.add('${k.toString()}: ${v.first}');
          }
        });
        if (messages.isNotEmpty) return messages.join('\n');
      }
    } catch (_) {}

    return "فشل تسجيل المنظمة (${res.statusCode})";
  }

  // ✅ لأن Django عندك: api/me/
  Future<Map<String, dynamic>?> getMyOrg() async {
    final token = await _token();
    if (token == null) return null;

    final res = await http.get(
      Uri.parse("$baseUrl/api/me/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  // ✅ لأن Django عندك: api/submit/
  Future<void> submitForReview() async {
    final token = await _token();
    if (token == null) throw Exception("أعد تسجيل الدخول");

    final res = await http.post(
      Uri.parse("$baseUrl/api/submit/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("فشل الإرسال للمراجعة: ${res.body}");
    }
  }
}
