import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class VolunteerService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<void> submitRequest(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");

    if (token == null) {
      throw Exception("غير مسجل الدخول");
    }

    final res = await http.post(
      Uri.parse("$baseUrl/api/volunteers/requests/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    if (res.statusCode != 201) {
      throw Exception("فشل إرسال طلب التطوع");
    }
  }
}
