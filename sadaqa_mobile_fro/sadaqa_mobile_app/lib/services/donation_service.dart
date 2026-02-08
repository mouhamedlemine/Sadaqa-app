import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DonationService {
  final String baseUrl;
  DonationService(this.baseUrl);

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  Future<void> donate({required int campaignId, required double amount}) async {
    final token = await _token();
    if (token == null) throw Exception("أعد تسجيل الدخول (لا يوجد توكن)");

    final res = await http.post(
      Uri.parse("$baseUrl/api/donations/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"campaign": campaignId, "amount": amount}),
    );

    if (res.statusCode != 201) {
      throw Exception("فشل التبرع: ${res.body}");
    }
  }
}
