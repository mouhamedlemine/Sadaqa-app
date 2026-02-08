import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStore {
  static const _idsKey = "favorite_campaign_ids";
  static const _campaignsKey = "favorite_campaigns_map";

  // ✅ IDs فقط
  static Future<Set<int>> getIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_idsKey) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
  }

  static Future<bool> isFav(int id) async {
    final ids = await getIds();
    return ids.contains(id);
  }

  static Future<void> toggle(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getIds();
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    await prefs.setStringList(_idsKey, ids.map((e) => e.toString()).toList());
  }

  // ✅ حفظ تفاصيل حملة للمفضلة (حتى نعرضها في favorites_page)
  static Future<void> saveCampaign(Map<String, dynamic> campaign) async {
    final prefs = await SharedPreferences.getInstance();

    final id = int.tryParse(campaign["id"].toString()) ?? 0;
    if (id == 0) return;

    final raw = prefs.getString(_campaignsKey);
    final Map<String, dynamic> map =
        raw == null ? {} : (jsonDecode(raw) as Map<String, dynamic>);

    map[id.toString()] = campaign;
    await prefs.setString(_campaignsKey, jsonEncode(map));
  }

  static Future<void> removeCampaign(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_campaignsKey);
    if (raw == null) return;

    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    map.remove(id.toString());
    await prefs.setString(_campaignsKey, jsonEncode(map));
  }

  static Future<List<Map<String, dynamic>>> getCampaigns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_campaignsKey);
    if (raw == null) return [];

    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    final items = <Map<String, dynamic>>[];

    for (final v in map.values) {
      if (v is Map) items.add(Map<String, dynamic>.from(v));
    }
    return items;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idsKey);
    await prefs.remove(_campaignsKey);
  }
}
