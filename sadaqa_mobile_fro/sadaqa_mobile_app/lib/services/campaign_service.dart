import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CampaignService {
  static const String _publicCampaignsPath = '/api/public/campaigns/';
  static const String _myCampaignsPath = '/api/my/campaigns/';

  Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// ✅ source:
  /// - "normal" => الحملات العادية فقط (organization = null)  [default]
  /// - "org"    => حملات المنظمات فقط (organization != null)
  /// - "all"    => كل الحملات
  Future<List<dynamic>> getPublicCampaigns({String source = "normal"}) async {
    final src = source.toLowerCase().trim();
    final path = (src == "normal")
        ? _publicCampaignsPath
        : '$_publicCampaignsPath?source=$src';

    final res = await http.get(_url(path), headers: _headers());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is List ? data : [];
    }
    throw Exception('Failed to load public campaigns (${res.statusCode}): ${res.body}');
  }

  Future<List<dynamic>> getMyCampaigns() async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated: access_token not found');

    final res = await http.get(_url(_myCampaignsPath), headers: _headers(token: token));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is List ? data : [];
    }
    throw Exception('Failed to load my campaigns (${res.statusCode}): ${res.body}');
  }

  Future<bool> createCampaign({
    required String title,
    required String description,
    required String goalAmount,
    int? organizationId,
  }) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated: access_token not found');

    final body = {
      'title': title,
      'description': description,
      'goal_amount': goalAmount,
      if (organizationId != null) 'organization': organizationId,
    };

    final res = await http.post(
      _url(_myCampaignsPath),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) return true;
    throw Exception('Create campaign failed (${res.statusCode}): ${res.body}');
  }

  Future<bool> updateCampaign({
    required int id,
    String? title,
    String? description,
    String? goalAmount,
    bool? isActive,
    int? organizationId,
  }) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated: access_token not found');

    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (goalAmount != null) 'goal_amount': goalAmount,
      if (isActive != null) 'is_active': isActive,
      if (organizationId != null) 'organization': organizationId,
    };

    final res = await http.patch(
      _url('$_myCampaignsPath$id/'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) return true;
    throw Exception('Update campaign failed (${res.statusCode}): ${res.body}');
  }

  Future<bool> deleteCampaign(int id) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated: access_token not found');

    final res = await http.delete(
      _url('$_myCampaignsPath$id/'),
      headers: _headers(token: token),
    );

    if (res.statusCode == 204) return true;
    throw Exception('Delete campaign failed (${res.statusCode}): ${res.body}');
  }

  Future<bool> closeCampaign(int id) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated: access_token not found');

    final res = await http.post(
      _url('$_myCampaignsPath$id/close/'),
      headers: _headers(token: token),
    );

    if (res.statusCode == 200) return true;
    throw Exception('Close campaign failed (${res.statusCode}): ${res.body}');
  }
}
