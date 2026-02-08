import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/campaign_service.dart';
import '../services/auth_service.dart';
import '../services/stripe_donation_service.dart';
import '../services/favorites_store.dart'; // ✅ Favoris
import '../config/api_config.dart';

import 'login_page.dart';
import 'new_campaign_page.dart';
import 'my_campaigns_page.dart';

class CampaignListPage extends StatefulWidget {
  /// ✅ Filtrage par catégorie (venant de Home)
  final String? category;

  const CampaignListPage({super.key, this.category});

  @override
  State<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends State<CampaignListPage> {
  final CampaignService _campaignService = CampaignService();
  final AuthService _authService = AuthService();
  final StripeDonationService _stripeService =
      StripeDonationService(ApiConfig.baseUrl);

  String _source = "normal"; // normal | org
  late Future<List<dynamic>> _campaignsFuture;

  bool _donating = false;
  bool _confirmedCheckoutOnce = false;

  // ✅ IDs favoris en mémoire (update rapide)
  Set<int> _favIds = {};

  @override
  void initState() {
    super.initState();
    _campaignsFuture = _campaignService.getPublicCampaigns(source: _source);
    _loadFavs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confirmCheckoutReturnIfNeeded();
    });
  }

  Future<void> _loadFavs() async {
    final ids = await FavoritesStore.getIds();
    if (!mounted) return;
    setState(() => _favIds = ids);
  }

  void _reload() {
    setState(() {
      _campaignsFuture = _campaignService.getPublicCampaigns(source: _source);
    });
    _loadFavs();
  }

  void _switchSource(String value) {
    if (_source == value) return;
    setState(() {
      _source = value;
      _campaignsFuture = _campaignService.getPublicCampaigns(source: _source);
    });
  }

  // ================= STRIPE CONFIRM (WEB) =================
  Future<void> _confirmCheckoutReturnIfNeeded() async {
    if (!kIsWeb || _confirmedCheckoutOnce) return;

    final fragment = Uri.base.fragment;
    if (!fragment.contains("payment-success")) return;

    final qIndex = fragment.indexOf("?");
    if (qIndex == -1) return;

    final params = Uri.splitQueryString(fragment.substring(qIndex + 1));
    final sessionId = params["session_id"];
    if (sessionId == null || sessionId.isEmpty) return;

    _confirmedCheckoutOnce = true;

    try {
      await _stripeService.confirmCheckoutSession(sessionId);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Paiement confirmé et campagne mise à jour")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur de confirmation : $e")),
      );
    }
  }

  // ================= DÉCONNEXION =================
  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Déconnexion", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  // ================= DON (BottomSheet) =================
  Future<void> _donate({required int campaignId, required String title}) async {
    if (_donating) return;

    final controller = TextEditingController(text: "10");

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.ltr, // ✅ Français
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Faire un don à la campagne",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [5, 10, 20, 50, 100].map((v) {
                      return OutlinedButton(
                        onPressed: () => controller.text = v.toString(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text("$v"),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Montant",
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        final v = double.tryParse(controller.text.trim());
                        if (v == null || v <= 0) return;
                        Navigator.pop(context, v);
                      },
                      child: const Text("Continuer le paiement"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (amount == null) return;

    setState(() => _donating = true);
    try {
      await _stripeService.donate(campaignId: campaignId, amount: amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Page de paiement ouverte")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Paiement échoué : $e")),
      );
    } finally {
      if (mounted) setState(() => _donating = false);
    }
  }

  // ================= Helpers =================
  double _d(dynamic v) => double.tryParse(v?.toString() ?? "0") ?? 0;

  String _money(double v) =>
      (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// ✅ Filtrage local par catégorie (sans changer l’API)
  List<dynamic> _applyCategoryFilter(List<dynamic> data) {
    final cat = widget.category;
    if (cat == null || cat.trim().isEmpty) return data;

    bool match(Map<String, dynamic> c) {
      final v1 = (c["category"] ?? "").toString().toLowerCase();
      final v2 = (c["category_slug"] ?? "").toString().toLowerCase();
      final v3 = (c["type"] ?? "").toString().toLowerCase();
      final target = cat.toLowerCase();
      return v1 == target || v2 == target || v3 == target;
    }

    return data.where((e) {
      if (e is Map<String, dynamic>) return match(e);
      return false;
    }).toList();
  }

  String _categoryTitle(String? cat) {
    switch ((cat ?? "").toLowerCase()) {
      case "education":
        return "Éducation";
      case "health":
        return "Santé";
      case "orphans":
        return "Orphelins";
      case "emergency":
        return "Urgence";
      case "water":
        return "Eau & assainissement";
      case "special_needs":
        return "Besoins spécifiques";
      default:
        return cat ?? "";
    }
  }

  // ✅ Activer/désactiver Favoris
  Future<void> _toggleFav(int id, Map<String, dynamic> campaign) async {
    final wasFav = _favIds.contains(id);

    await FavoritesStore.toggle(id);
    if (wasFav) {
      await FavoritesStore.removeCampaign(id);
    } else {
      await FavoritesStore.saveCampaign(campaign);
    }

    await _loadFavs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFav ? "Retiré des favoris" : "Ajouté aux favoris ❤️",
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr, // ✅ Français
      child: Theme(
        data: Theme.of(context).copyWith(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        ),
        child: Scaffold(
          backgroundColor: cs.surface,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    backgroundColor: cs.surface,
                    title: const Text(
                      "Campagnes",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    actions: [
                      IconButton(
                        tooltip: "Actualiser",
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        tooltip: "Mes campagnes",
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyCampaignsPage()),
                        ),
                        icon: const Icon(Icons.person_outline),
                      ),
                      IconButton(
                        tooltip: "Déconnexion",
                        onPressed: _confirmLogout,
                        icon: const Icon(Icons.logout),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: _segmentedTabs(),
                    ),
                  ),

                  if (widget.category != null && widget.category!.trim().isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_alt_outlined, color: Colors.purple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Catégorie : ${_categoryTitle(widget.category)}",
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CampaignListPage(),
                                    ),
                                  );
                                },
                                child: const Text("Retirer"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _headerHint(),
                    ),
                  ),

                  SliverFillRemaining(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      child: FutureBuilder<List<dynamic>>(
                        future: _campaignsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Erreur : ${snapshot.error}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final raw = snapshot.data ?? [];
                          final data = _applyCategoryFilter(raw);

                          if (data.isEmpty) {
                            final msg = (widget.category != null &&
                                    widget.category!.trim().isNotEmpty)
                                ? "Aucune campagne pour cette catégorie"
                                : (_source == "org"
                                    ? "Aucune campagne d’organisations"
                                    : "Aucune campagne publique");

                            return Center(
                              child: Text(
                                msg,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (_, i) {
                              final c = data[i] as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _campaignCard(c),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewCampaignPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Nouvelle campagne"),
          ),
        ),
      ),
    );
  }

  Widget _segmentedTabs() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segBtn(
              active: _source == "normal",
              text: "Campagnes publiques",
              icon: Icons.public,
              onTap: () => _switchSource("normal"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _segBtn(
              active: _source == "org",
              text: "Campagnes d’organisations",
              icon: Icons.apartment,
              onTap: () => _switchSource("org"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segBtn({
    required bool active,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : cs.primary),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : cs.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.purple.withOpacity(0.08),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.purple),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Choisissez une campagne puis appuyez sur « Faire un don » pour payer via Stripe.",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignCard(Map<String, dynamic> c) {
    final cs = Theme.of(context).colorScheme;

    final title = (c["title"] ?? "").toString();
    final goal = _d(c["goal_amount"]);
    final collected = _d(c["collected_amount"]);
    final progress = goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;

    final id = int.tryParse(c["id"].toString()) ?? 0;

    String orgName = "";
    final org = c["organization"];
    if (org is Map<String, dynamic>) {
      orgName = (org["name"] ?? "").toString();
    }

    final isFav = _favIds.contains(id);

    return Material(
      color: cs.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.06),
            )
          ],
        ),
        padding: const EdgeInsets.all(14),
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
                    color: cs.primary.withOpacity(0.12),
                  ),
                  child: Icon(Icons.volunteer_activism, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                // ✅ Bouton favoris
                IconButton(
                  tooltip: "Favoris",
                  onPressed: (id == 0) ? null : () => _toggleFav(id, c),
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.black45,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: cs.primary.withOpacity(0.10),
                  ),
                  child: Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900),
                  ),
                )
              ],
            ),

            if (orgName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.verified, size: 18, color: Colors.black54),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Organisation : $orgName",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatBox(
                    title: "Objectif",
                    value: _money(goal),
                    icon: Icons.flag_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatBox(
                    title: "Collecté",
                    value: _money(collected),
                    icon: Icons.savings_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: (_donating || id == 0)
                    ? null
                    : () => _donate(campaignId: id, title: title),
                icon: const Icon(Icons.payments_outlined),
                label: Text(_donating ? "Traitement..." : "Faire un don"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= STAT BOX =================
class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.primary.withOpacity(0.06),
        border: Border.all(color: cs.primary.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
