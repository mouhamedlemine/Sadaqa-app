import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/campaign_service.dart';
import 'campaign_list_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final CampaignService _service = CampaignService();

  late Future<List<Map<String, dynamic>>> _future;
  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _search.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Set<String>> _favIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList("favorite_campaign_ids") ?? []).toSet();
  }

  Future<void> _setFavIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("favorite_campaign_ids", ids.toList());
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final ids = await _favIds();

    // Fetch all public campaigns (or "all" if supported)
    final raw = await _service.getPublicCampaigns(source: "all");
    final all = raw.map((e) => Map<String, dynamic>.from(e)).toList();

    final favOnly = all.where((c) {
      final id = c["id"]?.toString();
      return id != null && ids.contains(id);
    }).toList();

    _all = favOnly;
    _filtered = List.from(_all);
    return favOnly;
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_all);
      } else {
        _filtered = _all.where((c) {
          final title = (c["title"] ?? "").toString().toLowerCase();
          return title.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
    _applyFilter();
  }

  double _d(dynamic v) => double.tryParse(v?.toString() ?? "0") ?? 0;

  String _money(double v) => (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _removeFromFav(String id) async {
    final ids = await _favIds();
    ids.remove(id);
    await _setFavIds(ids);

    setState(() {
      _all.removeWhere((c) => c["id"]?.toString() == id);
      _filtered.removeWhere((c) => c["id"]?.toString() == id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Retiré des favoris ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == "ar";

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F8FF),
          elevation: 0,
          title: const Text("Favoris", style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                children: [
                  // Search
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Rechercher dans les favoris…",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Text(
                              "Erreur : ${snap.error}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (_filtered.isEmpty) {
                          return _EmptyFav(
                            onExplore: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CampaignListPage()),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FavCampaignCard(
                              campaign: _filtered[i],
                              primary: cs.primary,
                              money: _money,
                              d: _d,
                              onRemove: () => _removeFromFav(_filtered[i]["id"].toString()),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFav extends StatelessWidget {
  const _EmptyFav({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 54, color: Colors.black45),
            const SizedBox(height: 10),
            const Text(
              "Aucune campagne favorite pour le moment",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Appuyez sur ❤️ sur une campagne pour l’ajouter ici.",
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore),
              label: const Text("Découvrir les campagnes"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavCampaignCard extends StatelessWidget {
  const _FavCampaignCard({
    required this.campaign,
    required this.primary,
    required this.money,
    required this.d,
    required this.onRemove,
  });

  final Map<String, dynamic> campaign;
  final Color primary;
  final String Function(double) money;
  final double Function(dynamic) d;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final title = (campaign["title"] ?? "").toString();
    final goal = d(campaign["goal_amount"]);
    final collected = d(campaign["collected_amount"]);
    final progress = goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: primary.withOpacity(0.12),
                ),
                child: Icon(Icons.volunteer_activism, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: "Retirer des favoris",
                onPressed: onRemove,
                icon: const Icon(Icons.favorite, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 10),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(title: "Objectif", value: money(goal), icon: Icons.flag_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(title: "Collecté", value: money(collected), icon: Icons.savings_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.03),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
