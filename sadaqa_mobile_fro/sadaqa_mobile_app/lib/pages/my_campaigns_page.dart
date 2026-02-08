import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/campaign_service.dart';
import '../services/auth_service.dart';

import 'edit_campaign_page.dart';
import 'campaign_list_page.dart';
import 'new_campaign_page.dart';
import 'login_page.dart';

class MyCampaignsPage extends StatefulWidget {
  const MyCampaignsPage({super.key});

  @override
  State<MyCampaignsPage> createState() => _MyCampaignsPageState();
}

class _MyCampaignsPageState extends State<MyCampaignsPage> with SingleTickerProviderStateMixin {
  final CampaignService _service = CampaignService();
  final AuthService _authService = AuthService();

  late Future<List<dynamic>> _future;
  String _selectedFilter = 'all'; // all, active, pending, rejected
  
  Map<String, dynamic>? _orgInfo;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyCampaigns();
    _loadOrgInfo();
  }

  Future<void> _loadOrgInfo() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() => _orgInfo = user);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void _refresh() {
    setState(() {
      _future = _service.getMyCampaigns();
    });
  }

  // ====== Navigation ======
  void _openPublicCampaigns() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CampaignListPage()),
    );
  }

  Future<void> _openNewCampaign() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewCampaignPage()),
    );
    if (created == true) _refresh();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Déconnexion",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Déconnexion", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _deleteCampaign(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmer la suppression",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text("Voulez-vous supprimer définitivement cette campagne ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Supprimer", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.deleteCampaign(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Campagne supprimée"),
          backgroundColor: const Color(0xff10b981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Échec de suppression : $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _openEdit(Map<String, dynamic> c) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditCampaignPage(campaign: c)),
    );
    if (updated == true) _refresh();
  }

  // ====== Utils ======
  double _d(dynamic v) => double.tryParse(v?.toString() ?? "0") ?? 0;

  String _money(double v) => (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "APPROVED":
        return const Color(0xFF10b981);
      case "REJECTED":
        return const Color(0xFFef4444);
      default:
        return const Color(0xFFf59e0b);
    }
  }

  String _statusText(String s) {
    switch (s.toUpperCase()) {
      case "APPROVED":
        return "Approuvée";
      case "REJECTED":
        return "Rejetée";
      default:
        return "En attente";
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toUpperCase()) {
      case "APPROVED":
        return Icons.check_circle_rounded;
      case "REJECTED":
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  bool _isApproved(String s) => s.toUpperCase() == "APPROVED";

  List<dynamic> _filterCampaigns(List<dynamic> campaigns) {
    if (_selectedFilter == 'all') return campaigns;
    
    return campaigns.where((c) {
      final status = (c['status'] ?? '').toString().toUpperCase();
      if (_selectedFilter == 'active') return status == 'APPROVED';
      if (_selectedFilter == 'pending') return status == 'PENDING';
      if (_selectedFilter == 'rejected') return status == 'REJECTED';
      return true;
    }).toList();
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == "ar";
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final maxWidth = kIsWeb ? 900.0 : double.infinity;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xfffaf5ff), Color(0xfff0f9ff)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(isArabic, isMobile),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: FutureBuilder<List<dynamic>>(
                        future: _future,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Color(0xff7a1fa2)),
                              ),
                            );
                          }
                          
                          if (snap.hasError) {
                            return _buildError(snap.error.toString());
                          }

                          final allItems = (snap.data ?? []).cast<dynamic>();
                          
                          if (allItems.isEmpty) {
                            return _emptyState(isMobile: isMobile);
                          }

                          return Column(
                            children: [
                              _buildStatsCards(allItems),
                              _buildFilterTabs(),
                              Expanded(
                                child: _buildCampaignsList(allItems, isMobile),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: isMobile ? _buildFAB() : null,
      ),
    );
  }

  Widget _buildAppBar(bool isArabic, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(color: Colors.purple.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Avatar & Info
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xff7a1fa2), Color(0xffc04ee6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _orgInfo?['name'] ?? 'Mon Organisation',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1f2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xff10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified, size: 10, color: Color(0xff10b981)),
                      SizedBox(width: 3),
                      Text(
                        'Vérifié',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xff10b981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions
          if (!isMobile) ...[
            FilledButton.icon(
              onPressed: _openNewCampaign,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Créer'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff7a1fa2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: _openPublicCampaigns,
            icon: const Icon(Icons.public_rounded),
            tooltip: 'Campagnes publiques',
            style: IconButton.styleFrom(
              backgroundColor: Colors.purple.withOpacity(0.08),
            ),
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            style: IconButton.styleFrom(
              backgroundColor: Colors.purple.withOpacity(0.08),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.08),
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<dynamic> campaigns) {
    final totalCampaigns = campaigns.length;
    final activeCampaigns = campaigns.where((c) => 
      (c['status'] ?? '').toString().toUpperCase() == 'APPROVED'
    ).length;
    final pendingCampaigns = campaigns.where((c) => 
      (c['status'] ?? '').toString().toUpperCase() == 'PENDING'
    ).length;
    
    final totalRaised = campaigns.fold<double>(0, (sum, c) => 
      sum + _d(c['collected_amount'])
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.campaign_rounded,
              label: 'Total',
              value: totalCampaigns.toString(),
              color: const Color(0xff7a1fa2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              icon: Icons.check_circle_rounded,
              label: 'Actives',
              value: activeCampaigns.toString(),
              color: const Color(0xff10b981),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              icon: Icons.pending_rounded,
              label: 'En attente',
              value: pendingCampaigns.toString(),
              color: const Color(0xfff59e0b),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              icon: Icons.attach_money_rounded,
              label: 'Collecté',
              value: totalRaised >= 1000 
                  ? '${(totalRaised / 1000).toStringAsFixed(0)}k'
                  : totalRaised.toStringAsFixed(0),
              color: const Color(0xff6366f1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Toutes', 'all'),
            const SizedBox(width: 8),
            _filterChip('Actives', 'active'),
            const SizedBox(width: 8),
            _filterChip('En attente', 'pending'),
            const SizedBox(width: 8),
            _filterChip('Rejetées', 'rejected'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xff7a1fa2), Color(0xffc04ee6)])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.purple.withOpacity(0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xff6b7280),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignsList(List<dynamic> allCampaigns, bool isMobile) {
    final filteredCampaigns = _filterCampaigns(allCampaigns);

    if (filteredCampaigns.isEmpty) {
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: const Color(0xff7a1fa2),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 8, 16, isMobile ? 100 : 16),
        itemCount: filteredCampaigns.length,
        itemBuilder: (_, i) {
          final c = (filteredCampaigns[i] as Map).cast<String, dynamic>();
          return _campaignCard(c, isMobile: isMobile);
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "Erreur de chargement",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff7a1fa2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    String message = 'Aucun résultat';
    if (_selectedFilter == 'active') message = 'Aucune campagne active';
    if (_selectedFilter == 'pending') message = 'Aucune campagne en attente';
    if (_selectedFilter == 'rejected') message = 'Aucune campagne rejetée';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.purple.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({required bool isMobile}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withOpacity(0.08),
              ),
              child: Icon(Icons.campaign_outlined, size: 50, color: Colors.purple.withOpacity(0.4)),
            ),
            const SizedBox(height: 20),
            const Text(
              "Vous n'avez aucune campagne pour le moment",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Créez une nouvelle campagne puis attendez l'approbation de l'administrateur.",
              style: TextStyle(color: Colors.black54, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (isMobile) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _openNewCampaign,
                  icon: const Icon(Icons.add),
                  label: const Text("Créer une campagne"),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff7a1fa2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _openPublicCampaigns,
                  icon: const Icon(Icons.public),
                  label: const Text("Voir les campagnes publiques"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff7a1fa2),
                    side: const BorderSide(color: Color(0xff7a1fa2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _openNewCampaign,
                    icon: const Icon(Icons.add),
                    label: const Text("Créer une campagne"),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff7a1fa2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openPublicCampaigns,
                    icon: const Icon(Icons.public),
                    label: const Text("Voir les campagnes publiques"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff7a1fa2),
                      side: const BorderSide(color: Color(0xff7a1fa2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _campaignCard(Map<String, dynamic> c, {required bool isMobile}) {
    final int id = int.tryParse(c["id"]?.toString() ?? "0") ?? 0;
    final String title = (c["title"] ?? "Sans titre").toString();
    final String description = (c["description"] ?? "").toString();
    final String status = (c["status"] ?? "PENDING").toString();

    final double goal = _d(c["goal_amount"]);
    final double collected = _d(c["collected_amount"]);
    final double progress = goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;

    final String reason = (c["rejection_reason"] ?? "").toString().trim();
    final bool canEditOrDelete = !_isApproved(status);
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1f2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(status), size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              _statusText(status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.6),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_money(collected)} FCFA',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff7a1fa2),
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation(Color(0xff7a1fa2)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Objectif: ${_money(goal)} FCFA',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),

                  // Rejection Reason
                  if (status.toUpperCase() == "REJECTED") ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFef4444).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFef4444).withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFef4444), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reason.isEmpty ? 'Aucune raison fournie' : reason,
                              style: const TextStyle(color: Color(0xFFef4444), height: 1.3, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text("Modifier"),
                          onPressed: canEditOrDelete ? () => _openEdit(c) : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            foregroundColor: const Color(0xff7a1fa2),
                            side: const BorderSide(color: Color(0xff7a1fa2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_rounded, size: 16),
                          label: const Text("Supprimer"),
                          onPressed: (canEditOrDelete && id != 0) ? () => _deleteCampaign(id) : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (!canEditOrDelete) ...[
                    const SizedBox(height: 10),
                    Text(
                      "⚠️ Impossible de modifier/supprimer une campagne approuvée.",
                      style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.5), height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xff7a1fa2), Color(0xffc04ee6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _openNewCampaign,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Créer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}

















// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart'; // ✅ مهم لـ MissingPluginException

// import '../services/campaign_service.dart';
// import '../services/auth_service.dart';

// import 'edit_campaign_page.dart';
// import 'campaign_list_page.dart';
// import 'new_campaign_page.dart';

// class MyCampaignsPage extends StatefulWidget {
//   const MyCampaignsPage({super.key});

//   @override
//   State<MyCampaignsPage> createState() => _MyCampaignsPageState();
// }

// class _MyCampaignsPageState extends State<MyCampaignsPage>
//     with SingleTickerProviderStateMixin {
//   final CampaignService _service = CampaignService();
//   final AuthService _authService = AuthService();

//   late Future<List<dynamic>> _future;
//   String _selectedFilter = 'all';
//   Map<String, dynamic>? _orgInfo;

//   @override
//   void initState() {
//     super.initState();
//     _future = _service.getMyCampaigns();
//     _loadOrgInfo();
//   }

//   Future<void> _loadOrgInfo() async {
//     try {
//       final user = await _authService.getCurrentUser();
//       if (mounted) setState(() => _orgInfo = user);
//     } catch (_) {}
//   }

//   void _refresh() {
//     setState(() {
//       _future = _service.getMyCampaigns();
//     });
//   }

//   // ================= LOGOUT (FIXED) =================
//   Future<void> _logout() async {
//     final isArabic = Localizations.localeOf(context).languageCode == "ar";

//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text(isArabic ? "تسجيل الخروج" : "Déconnexion"),
//         content: Text(
//           isArabic
//               ? "هل تريد حقاً تسجيل الخروج؟"
//               : "Voulez-vous vraiment vous déconnecter ?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text(isArabic ? "إلغاء" : "Annuler"),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: FilledButton.styleFrom(backgroundColor: Colors.red),
//             child: Text(isArabic ? "خروج" : "Déconnexion"),
//           ),
//         ],
//       ),
//     );

//     if (ok != true) return;

//     try {
//       await _authService.logout();
//     } on MissingPluginException {
//       // ✅ تجاهل خطأ flutter_facebook_auth
//     } catch (e) {
//       final msg = e.toString();
//       final isPluginIssue = msg.contains('MissingPluginException') ||
//           msg.contains('flutter_facebook_auth') ||
//           msg.contains('logOut');

//       if (!isPluginIssue) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               isArabic
//                   ? "خطأ في تسجيل الخروج"
//                   : "Erreur de déconnexion",
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//     }

//     if (!mounted) return;
//     Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
//   }
//   // =================================================

//   double _d(dynamic v) => double.tryParse(v?.toString() ?? "0") ?? 0;
//   String _money(double v) =>
//       (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

//   Color _statusColor(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return const Color(0xFF10b981);
//       case "REJECTED":
//         return const Color(0xFFef4444);
//       default:
//         return const Color(0xFFf59e0b);
//     }
//   }

//   String _statusText(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return "Approuvée";
//       case "REJECTED":
//         return "Rejetée";
//       default:
//         return "En attente";
//     }
//   }

//   IconData _statusIcon(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return Icons.check_circle_rounded;
//       case "REJECTED":
//         return Icons.cancel_rounded;
//       default:
//         return Icons.schedule_rounded;
//     }
//   }

//   bool _isApproved(String s) => s.toUpperCase() == "APPROVED";

//   List<dynamic> _filterCampaigns(List<dynamic> campaigns) {
//     if (_selectedFilter == 'all') return campaigns;
//     return campaigns.where((c) {
//       final status = (c['status'] ?? '').toString().toUpperCase();
//       if (_selectedFilter == 'active') return status == 'APPROVED';
//       if (_selectedFilter == 'pending') return status == 'PENDING';
//       if (_selectedFilter == 'rejected') return status == 'REJECTED';
//       return true;
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isArabic = Localizations.localeOf(context).languageCode == "ar";
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 768;
//     final maxWidth = kIsWeb ? 900.0 : double.infinity;

//     return Directionality(
//       textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
//       child: Scaffold(
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [Color(0xfffaf5ff), Color(0xfff0f9ff)],
//             ),
//           ),
//           child: SafeArea(
//             child: Column(
//               children: [
//                 _buildAppBar(isArabic, isMobile),
//                 Expanded(
//                   child: Center(
//                     child: ConstrainedBox(
//                       constraints: BoxConstraints(maxWidth: maxWidth),
//                       child: FutureBuilder<List<dynamic>>(
//                         future: _future,
//                         builder: (context, snap) {
//                           if (snap.connectionState != ConnectionState.done) {
//                             return const Center(
//                               child: CircularProgressIndicator(),
//                             );
//                           }
//                           if (snap.hasError) {
//                             return Center(child: Text(snap.error.toString()));
//                           }

//                           final allItems = (snap.data ?? []);
//                           if (allItems.isEmpty) {
//                             return const Center(child: Text("Aucune campagne"));
//                           }

//                           return Column(
//                             children: [
//                               _buildFilterTabs(),
//                               Expanded(
//                                 child: ListView.builder(
//                                   padding: const EdgeInsets.all(16),
//                                   itemCount:
//                                       _filterCampaigns(allItems).length,
//                                   itemBuilder: (_, i) {
//                                     final c = _filterCampaigns(allItems)[i]
//                                         as Map<String, dynamic>;
//                                     return _campaignCard(c);
//                                   },
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: () async {
//             final created = await Navigator.push<bool>(
//               context,
//               MaterialPageRoute(builder: (_) => const NewCampaignPage()),
//             );
//             if (created == true) _refresh();
//           },
//           child: const Icon(Icons.add),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar(bool isArabic, bool isMobile) {
//     return AppBar(
//       title: Text(_orgInfo?['name'] ?? 'Mon Organisation'),
//       actions: [
//         IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
//         IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
//       ],
//     );
//   }

//   Widget _buildFilterTabs() {
//     return Padding(
//       padding: const EdgeInsets.all(8),
//       child: Wrap(
//         spacing: 8,
//         children: [
//           _chip('Toutes', 'all'),
//           _chip('Actives', 'active'),
//           _chip('En attente', 'pending'),
//           _chip('Rejetées', 'rejected'),
//         ],
//       ),
//     );
//   }

//   Widget _chip(String label, String value) {
//     final selected = _selectedFilter == value;
//     return ChoiceChip(
//       label: Text(label),
//       selected: selected,
//       onSelected: (_) => setState(() => _selectedFilter = value),
//     );
//   }

//   Widget _campaignCard(Map<String, dynamic> c) {
//     final title = c['title'] ?? '';
//     final goal = _d(c['goal_amount']);
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: ListTile(
//         title: Text(title),
//         subtitle: Text("Objectif: \$${_money(goal)}"),
//         trailing: Chip(
//           label: Text(_statusText(c['status'] ?? '')),
//           backgroundColor: _statusColor(c['status'] ?? ''),
//         ),
//       ),
//     );
//   }
// }














// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';

// import '../services/campaign_service.dart';
// import '../services/auth_service.dart';

// import 'edit_campaign_page.dart';
// import 'campaign_list_page.dart';
// import 'new_campaign_page.dart';
// import 'login_page.dart';

// class MyCampaignsPage extends StatefulWidget {
//   const MyCampaignsPage({super.key});

//   @override
//   State<MyCampaignsPage> createState() => _MyCampaignsPageState();
// }

// class _MyCampaignsPageState extends State<MyCampaignsPage> with SingleTickerProviderStateMixin {
//   final CampaignService _service = CampaignService();
//   final AuthService _authService = AuthService();

//   late Future<List<dynamic>> _future;
//   String _selectedFilter = 'all'; // all, active, pending, rejected
  
//   Map<String, dynamic>? _orgInfo;

//   @override
//   void initState() {
//     super.initState();
//     _future = _service.getMyCampaigns();
//     _loadOrgInfo();
//   }

//   Future<void> _loadOrgInfo() async {
//     try {
//       final user = await _authService.getCurrentUser();
//       if (mounted) {
//         setState(() => _orgInfo = user);
//       }
//     } catch (e) {
//       // Ignore errors
//     }
//   }

//   void _refresh() {
//     setState(() {
//       _future = _service.getMyCampaigns();
//     });
//   }

//   // ====== Navigation ======
//   void _openPublicCampaigns() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const CampaignListPage()),
//     );
//   }

//   Future<void> _openNewCampaign() async {
//     final created = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(builder: (_) => const NewCampaignPage()),
//     );
//     if (created == true) _refresh();
//   }

//   Future<void> _logout() async {
//     final isArabic = Localizations.localeOf(context).languageCode == "ar";
    
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text(
//           isArabic ? "تسجيل الخروج" : "Déconnexion",
//           style: const TextStyle(fontWeight: FontWeight.w900),
//         ),
//         content: Text(
//           isArabic 
//               ? "هل تريد حقاً تسجيل الخروج؟" 
//               : "Voulez-vous vraiment vous déconnecter ?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text(isArabic ? "إلغاء" : "Annuler"),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: FilledButton.styleFrom(
//               backgroundColor: Colors.red,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: Text(
//               isArabic ? "تسجيل الخروج" : "Déconnexion",
//               style: const TextStyle(fontWeight: FontWeight.w800),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (ok != true) return;

//     try {
//       await _authService.logout();
//       if (!mounted) return;

//       // ✅ استخدام pushNamedAndRemoveUntil بدلاً من pushAndRemoveUntil
//       Navigator.of(context).pushNamedAndRemoveUntil(
//         '/',
//         (route) => false,
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             isArabic 
//                 ? "خطأ في تسجيل الخروج: $e" 
//                 : "Erreur de déconnexion: $e",
//           ),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//     }
//   }

//   Future<void> _deleteCampaign(int id) async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           "Confirmer la suppression",
//           style: TextStyle(fontWeight: FontWeight.w900),
//         ),
//         content: const Text("Voulez-vous supprimer définitivement cette campagne ?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Annuler"),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: FilledButton.styleFrom(
//               backgroundColor: Colors.red,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text("Supprimer", style: TextStyle(fontWeight: FontWeight.w800)),
//           ),
//         ],
//       ),
//     );

//     if (ok != true) return;

//     try {
//       await _service.deleteCampaign(id);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text("✅ Campagne supprimée"),
//           backgroundColor: const Color(0xff10b981),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//       _refresh();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("❌ Échec de suppression : $e"),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//     }
//   }

//   Future<void> _openEdit(Map<String, dynamic> c) async {
//     final updated = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(builder: (_) => EditCampaignPage(campaign: c)),
//     );
//     if (updated == true) _refresh();
//   }

//   // ====== Utils ======
//   double _d(dynamic v) => double.tryParse(v?.toString() ?? "0") ?? 0;

//   String _money(double v) => (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

//   Color _statusColor(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return const Color(0xFF10b981);
//       case "REJECTED":
//         return const Color(0xFFef4444);
//       default:
//         return const Color(0xFFf59e0b);
//     }
//   }

//   String _statusText(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return "Approuvée";
//       case "REJECTED":
//         return "Rejetée";
//       default:
//         return "En attente";
//     }
//   }

//   IconData _statusIcon(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return Icons.check_circle_rounded;
//       case "REJECTED":
//         return Icons.cancel_rounded;
//       default:
//         return Icons.schedule_rounded;
//     }
//   }

//   bool _isApproved(String s) => s.toUpperCase() == "APPROVED";

//   List<dynamic> _filterCampaigns(List<dynamic> campaigns) {
//     if (_selectedFilter == 'all') return campaigns;
    
//     return campaigns.where((c) {
//       final status = (c['status'] ?? '').toString().toUpperCase();
//       if (_selectedFilter == 'active') return status == 'APPROVED';
//       if (_selectedFilter == 'pending') return status == 'PENDING';
//       if (_selectedFilter == 'rejected') return status == 'REJECTED';
//       return true;
//     }).toList();
//   }

//   // ====== UI ======
//   @override
//   Widget build(BuildContext context) {
//     final isArabic = Localizations.localeOf(context).languageCode == "ar";
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 768;
//     final maxWidth = kIsWeb ? 900.0 : double.infinity;

//     return Directionality(
//       textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
//       child: Scaffold(
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [Color(0xfffaf5ff), Color(0xfff0f9ff)],
//             ),
//           ),
//           child: SafeArea(
//             child: Column(
//               children: [
//                 _buildAppBar(isArabic, isMobile),
//                 Expanded(
//                   child: Center(
//                     child: ConstrainedBox(
//                       constraints: BoxConstraints(maxWidth: maxWidth),
//                       child: FutureBuilder<List<dynamic>>(
//                         future: _future,
//                         builder: (context, snap) {
//                           if (snap.connectionState != ConnectionState.done) {
//                             return const Center(
//                               child: CircularProgressIndicator(
//                                 valueColor: AlwaysStoppedAnimation(Color(0xff7a1fa2)),
//                               ),
//                             );
//                           }
                          
//                           if (snap.hasError) {
//                             return _buildError(snap.error.toString());
//                           }

//                           final allItems = (snap.data ?? []).cast<dynamic>();
                          
//                           if (allItems.isEmpty) {
//                             return _emptyState(isMobile: isMobile);
//                           }

//                           return Column(
//                             children: [
//                               _buildStatsCards(allItems),
//                               _buildFilterTabs(),
//                               Expanded(
//                                 child: _buildCampaignsList(allItems, isMobile),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         floatingActionButton: isMobile ? _buildFAB() : null,
//       ),
//     );
//   }

//   Widget _buildAppBar(bool isArabic, bool isMobile) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.85),
//         border: Border(
//           bottom: BorderSide(color: Colors.purple.withOpacity(0.1)),
//         ),
//       ),
//       child: Row(
//         children: [
//           // Avatar & Info
//           Container(
//             height: 50,
//             width: 50,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: const LinearGradient(
//                 colors: [Color(0xff7a1fa2), Color(0xffc04ee6)],
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.purple.withOpacity(0.3),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: const Icon(Icons.business, color: Colors.white, size: 24),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _orgInfo?['name'] ?? 'Mon Organisation',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xff1f2937),
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 2),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: const Color(0xff10b981).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: const [
//                       Icon(Icons.verified, size: 10, color: Color(0xff10b981)),
//                       SizedBox(width: 3),
//                       Text(
//                         'Vérifié',
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: Color(0xff10b981),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Actions
//           if (!isMobile) ...[
//             FilledButton.icon(
//               onPressed: _openNewCampaign,
//               icon: const Icon(Icons.add, size: 18),
//               label: const Text('Créer'),
//               style: FilledButton.styleFrom(
//                 backgroundColor: const Color(0xff7a1fa2),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//             const SizedBox(width: 8),
//           ],
//           IconButton(
//             onPressed: _openPublicCampaigns,
//             icon: const Icon(Icons.public_rounded),
//             tooltip: 'Campagnes publiques',
//             style: IconButton.styleFrom(
//               backgroundColor: Colors.purple.withOpacity(0.08),
//             ),
//           ),
//           IconButton(
//             onPressed: _refresh,
//             icon: const Icon(Icons.refresh_rounded),
//             tooltip: 'Actualiser',
//             style: IconButton.styleFrom(
//               backgroundColor: Colors.purple.withOpacity(0.08),
//             ),
//           ),
//           IconButton(
//             onPressed: _logout,
//             icon: const Icon(Icons.logout_rounded),
//             tooltip: 'Déconnexion',
//             style: IconButton.styleFrom(
//               backgroundColor: Colors.red.withOpacity(0.08),
//               foregroundColor: Colors.red,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsCards(List<dynamic> campaigns) {
//     final totalCampaigns = campaigns.length;
//     final activeCampaigns = campaigns.where((c) => 
//       (c['status'] ?? '').toString().toUpperCase() == 'APPROVED'
//     ).length;
//     final pendingCampaigns = campaigns.where((c) => 
//       (c['status'] ?? '').toString().toUpperCase() == 'PENDING'
//     ).length;
    
//     final totalRaised = campaigns.fold<double>(0, (sum, c) => 
//       sum + _d(c['collected_amount'])
//     );

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           Expanded(
//             child: _statCard(
//               icon: Icons.campaign_rounded,
//               label: 'Total',
//               value: totalCampaigns.toString(),
//               color: const Color(0xff7a1fa2),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: _statCard(
//               icon: Icons.check_circle_rounded,
//               label: 'Actives',
//               value: activeCampaigns.toString(),
//               color: const Color(0xff10b981),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: _statCard(
//               icon: Icons.pending_rounded,
//               label: 'En attente',
//               value: pendingCampaigns.toString(),
//               color: const Color(0xfff59e0b),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: _statCard(
//               icon: Icons.attach_money_rounded,
//               label: 'Collecté',
//               value: totalRaised >= 1000 
//                   ? '${(totalRaised / 1000).toStringAsFixed(0)}k'
//                   : totalRaised.toStringAsFixed(0),
//               color: const Color(0xff6366f1),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statCard({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: color.withOpacity(0.15)),
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 22),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 10,
//               color: Colors.black.withOpacity(0.5),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterTabs() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             _filterChip('Toutes', 'all'),
//             const SizedBox(width: 8),
//             _filterChip('Actives', 'active'),
//             const SizedBox(width: 8),
//             _filterChip('En attente', 'pending'),
//             const SizedBox(width: 8),
//             _filterChip('Rejetées', 'rejected'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filterChip(String label, String value) {
//     final isSelected = _selectedFilter == value;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedFilter = value),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
//         decoration: BoxDecoration(
//           gradient: isSelected
//               ? const LinearGradient(colors: [Color(0xff7a1fa2), Color(0xffc04ee6)])
//               : null,
//           color: isSelected ? null : Colors.white.withOpacity(0.9),
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(
//             color: isSelected ? Colors.transparent : Colors.purple.withOpacity(0.2),
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: Colors.purple.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ]
//               : null,
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSelected ? Colors.white : const Color(0xff6b7280),
//             fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
//             fontSize: 12,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCampaignsList(List<dynamic> allCampaigns, bool isMobile) {
//     final filteredCampaigns = _filterCampaigns(allCampaigns);

//     if (filteredCampaigns.isEmpty) {
//       return _buildNoResultsState();
//     }

//     return RefreshIndicator(
//       onRefresh: () async => _refresh(),
//       color: const Color(0xff7a1fa2),
//       child: ListView.builder(
//         padding: EdgeInsets.fromLTRB(16, 8, 16, isMobile ? 100 : 16),
//         itemCount: filteredCampaigns.length,
//         itemBuilder: (_, i) {
//           final c = (filteredCampaigns[i] as Map).cast<String, dynamic>();
//           return _campaignCard(c, isMobile: isMobile);
//         },
//       ),
//     );
//   }

//   Widget _buildError(String error) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
//             const SizedBox(height: 16),
//             Text(
//               "Erreur de chargement",
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               error,
//               style: const TextStyle(color: Colors.red),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             FilledButton.icon(
//               onPressed: _refresh,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Réessayer'),
//               style: FilledButton.styleFrom(
//                 backgroundColor: const Color(0xff7a1fa2),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNoResultsState() {
//     String message = 'Aucun résultat';
//     if (_selectedFilter == 'active') message = 'Aucune campagne active';
//     if (_selectedFilter == 'pending') message = 'Aucune campagne en attente';
//     if (_selectedFilter == 'rejected') message = 'Aucune campagne rejetée';

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.search_off_rounded, size: 64, color: Colors.purple.withOpacity(0.3)),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff6b7280)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyState({required bool isMobile}) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               height: 100,
//               width: 100,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.purple.withOpacity(0.08),
//               ),
//               child: Icon(Icons.campaign_outlined, size: 50, color: Colors.purple.withOpacity(0.4)),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Vous n'avez aucune campagne pour le moment",
//               style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               "Créez une nouvelle campagne puis attendez l'approbation de l'administrateur.",
//               style: TextStyle(color: Colors.black54, height: 1.4),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),

//             if (isMobile) ...[
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: FilledButton.icon(
//                   onPressed: _openNewCampaign,
//                   icon: const Icon(Icons.add),
//                   label: const Text("Créer une campagne"),
//                   style: FilledButton.styleFrom(
//                     backgroundColor: const Color(0xff7a1fa2),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: OutlinedButton.icon(
//                   onPressed: _openPublicCampaigns,
//                   icon: const Icon(Icons.public),
//                   label: const Text("Voir les campagnes publiques"),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: const Color(0xff7a1fa2),
//                     side: const BorderSide(color: Color(0xff7a1fa2)),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                   ),
//                 ),
//               ),
//             ] else ...[
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: [
//                   FilledButton.icon(
//                     onPressed: _openNewCampaign,
//                     icon: const Icon(Icons.add),
//                     label: const Text("Créer une campagne"),
//                     style: FilledButton.styleFrom(
//                       backgroundColor: const Color(0xff7a1fa2),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                     ),
//                   ),
//                   OutlinedButton.icon(
//                     onPressed: _openPublicCampaigns,
//                     icon: const Icon(Icons.public),
//                     label: const Text("Voir les campagnes publiques"),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: const Color(0xff7a1fa2),
//                       side: const BorderSide(color: Color(0xff7a1fa2)),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _campaignCard(Map<String, dynamic> c, {required bool isMobile}) {
//     final int id = int.tryParse(c["id"]?.toString() ?? "0") ?? 0;
//     final String title = (c["title"] ?? "Sans titre").toString();
//     final String description = (c["description"] ?? "").toString();
//     final String status = (c["status"] ?? "PENDING").toString();

//     final double goal = _d(c["goal_amount"]);
//     final double collected = _d(c["collected_amount"]);
//     final double progress = goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;

//     final String reason = (c["rejection_reason"] ?? "").toString().trim();
//     final bool canEditOrDelete = !_isApproved(status);
//     final statusColor = _statusColor(status);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(18),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.9),
//               borderRadius: BorderRadius.circular(18),
//               border: Border.all(color: Colors.white.withOpacity(0.3)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.06),
//                   blurRadius: 16,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Title + Status
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           title,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xff1f2937),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: statusColor,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: statusColor.withOpacity(0.3),
//                               blurRadius: 6,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(_statusIcon(status), size: 14, color: Colors.white),
//                             const SizedBox(width: 5),
//                             Text(
//                               _statusText(status),
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 11,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   if (description.isNotEmpty) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       description,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.black.withOpacity(0.6),
//                         height: 1.4,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],

//                   const SizedBox(height: 14),

//                   // Progress Bar
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           RichText(
//                             text: TextSpan(
//                               children: [
//                                 TextSpan(
//                                   text: '\$',
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black.withOpacity(0.5),
//                                   ),
//                                 ),
//                                 TextSpan(
//                                   text: _money(collected),
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Color(0xff7a1fa2),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                             decoration: BoxDecoration(
//                               color: Colors.purple.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '${(progress * 100).toStringAsFixed(0)}%',
//                               style: const TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w700,
//                                 color: Color(0xff7a1fa2),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: LinearProgressIndicator(
//                           value: progress,
//                           minHeight: 8,
//                           backgroundColor: Colors.purple.withOpacity(0.1),
//                           valueColor: const AlwaysStoppedAnimation(Color(0xff7a1fa2)),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       RichText(
//                         text: TextSpan(
//                           children: [
//                             TextSpan(
//                               text: 'Objectif: ',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.black.withOpacity(0.4),
//                               ),
//                             ),
//                             TextSpan(
//                               text: '\$',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: Colors.black.withOpacity(0.5),
//                               ),
//                             ),
//                             TextSpan(
//                               text: _money(goal),
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black.withOpacity(0.6),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   // Rejection Reason
//                   if (status.toUpperCase() == "REJECTED") ...[
//                     const SizedBox(height: 12),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFef4444).withOpacity(0.08),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: const Color(0xFFef4444).withOpacity(0.2)),
//                       ),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Icon(Icons.info_outline, color: Color(0xFFef4444), size: 18),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               reason.isEmpty ? 'Aucune raison fournie' : reason,
//                               style: const TextStyle(color: Color(0xFFef4444), height: 1.3, fontSize: 12),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],

//                   const SizedBox(height: 14),

//                   // Action Buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           icon: const Icon(Icons.edit_rounded, size: 16),
//                           label: const Text("Modifier"),
//                           onPressed: canEditOrDelete ? () => _openEdit(c) : null,
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 11),
//                             foregroundColor: const Color(0xff7a1fa2),
//                             side: const BorderSide(color: Color(0xff7a1fa2)),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           icon: const Icon(Icons.delete_rounded, size: 16),
//                           label: const Text("Supprimer"),
//                           onPressed: (canEditOrDelete && id != 0) ? () => _deleteCampaign(id) : null,
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 11),
//                             foregroundColor: Colors.red,
//                             side: const BorderSide(color: Colors.red),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   if (!canEditOrDelete) ...[
//                     const SizedBox(height: 10),
//                     Text(
//                       "⚠️ Impossible de modifier/supprimer une campagne approuvée.",
//                       style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.5), height: 1.3),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFAB() {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         gradient: const LinearGradient(
//           colors: [Color(0xff7a1fa2), Color(0xffc04ee6)],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.purple.withOpacity(0.4),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: FloatingActionButton.extended(
//         onPressed: _openNewCampaign,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         icon: const Icon(Icons.add_rounded, size: 24),
//         label: const Text(
//           'Créer',
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//         ),
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';

// import '../services/campaign_service.dart';
// import '../services/auth_service.dart';

// import 'edit_campaign_page.dart';
// import 'campaign_list_page.dart';
// import 'new_campaign_page.dart';
// import 'login_page.dart';

// class MyCampaignsPage extends StatefulWidget {
//   const MyCampaignsPage({super.key});

//   @override
//   State<MyCampaignsPage> createState() => _MyCampaignsPageState();
// }

// class _MyCampaignsPageState extends State<MyCampaignsPage> {
//   final CampaignService _service = CampaignService();
//   final AuthService _authService = AuthService();

//   late Future<List<dynamic>> _future;

//   @override
//   void initState() {
//     super.initState();
//     _future = _service.getMyCampaigns();
//   }

//   void _refresh() {
//     setState(() {
//       _future = _service.getMyCampaigns();
//     });
//   }

//   // ====== Navigation ======
//   void _openPublicCampaigns() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const CampaignListPage()),
//     );
//   }

//   Future<void> _openNewCampaign() async {
//     final created = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(builder: (_) => const NewCampaignPage()),
//     );
//     if (created == true) _refresh();
//   }

//   Future<void> _logout() async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text(
//           "Déconnexion",
//           style: TextStyle(fontWeight: FontWeight.w900),
//         ),
//         content: const Text("Voulez-vous vous déconnecter ?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Annuler"),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text("Déconnexion", style: TextStyle(fontWeight: FontWeight.w800)),
//           ),
//         ],
//       ),
//     );

//     if (ok != true) return;

//     await _authService.logout();
//     if (!mounted) return;

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginPage()),
//       (_) => false,
//     );
//   }

//   Future<void> _deleteCampaign(int id) async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text(
//           "Confirmer la suppression",
//           style: TextStyle(fontWeight: FontWeight.w900),
//         ),
//         content: const Text("Voulez-vous supprimer définitivement cette campagne ?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Annuler"),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text("Supprimer", style: TextStyle(fontWeight: FontWeight.w800)),
//           ),
//         ],
//       ),
//     );

//     if (ok != true) return;

//     try {
//       await _service.deleteCampaign(id);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("✅ Campagne supprimée")),
//       );
//       _refresh();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ Échec de suppression : $e")),
//       );
//     }
//   }

//   Future<void> _openEdit(Map<String, dynamic> c) async {
//     final updated = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(builder: (_) => EditCampaignPage(campaign: c)),
//     );
//     if (updated == true) _refresh();
//   }

//   // ====== Utils ======
//   double _d(dynamic v) => double.tryParse(v?.toString() ?? "0") ?? 0;

//   String _money(double v) => (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

//   Color _statusColor(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return const Color(0xFF16A34A);
//       case "REJECTED":
//         return const Color(0xFFDC2626);
//       default:
//         return const Color(0xFFF59E0B);
//     }
//   }

//   String _statusText(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return "Approuvée";
//       case "REJECTED":
//         return "Rejetée";
//       default:
//         return "En cours de validation";
//     }
//   }

//   IconData _statusIcon(String s) {
//     switch (s.toUpperCase()) {
//       case "APPROVED":
//         return Icons.verified_rounded;
//       case "REJECTED":
//         return Icons.cancel_rounded;
//       default:
//         return Icons.hourglass_top_rounded;
//     }
//   }

//   bool _isApproved(String s) => s.toUpperCase() == "APPROVED";

//   // ====== UI ======
//   @override
//   Widget build(BuildContext context) {
//     // عرض مناسب على الويب حتى لا تصبح الصفحة "فارغة"
//     final maxWidth = kIsWeb ? 600.0 : double.infinity;

//     final isArabic = Localizations.localeOf(context).languageCode == "ar";
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 768;

//     return Directionality(
//       textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF6F7FB),

//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0.5,
//           title: const Text(
//             "Mes campagnes",
//             style: TextStyle(fontWeight: FontWeight.w900),
//           ),
//           actions: [
//             // زر أعلى للويب فقط
//             if (kIsWeb)
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//                 child: FilledButton.icon(
//                   onPressed: _openNewCampaign,
//                   icon: const Icon(Icons.add),
//                   label: const Text("Créer une campagne"),
//                   style: FilledButton.styleFrom(
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                 ),
//               ),
//             IconButton(
//               tooltip: "Campagnes publiques",
//               icon: const Icon(Icons.public),
//               onPressed: _openPublicCampaigns,
//             ),
//             IconButton(
//               tooltip: "Actualiser",
//               icon: const Icon(Icons.refresh),
//               onPressed: _refresh,
//             ),
//             IconButton(
//               tooltip: "Déconnexion",
//               icon: const Icon(Icons.logout),
//               onPressed: _logout,
//             ),
//           ],
//         ),

//         // ✅ زر ثابت أسفل الشاشة للهاتف (أفضل من FAB)
//         bottomNavigationBar: (kIsWeb)
//             ? null
//             : SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//                   child: SizedBox(
//                     height: 52,
//                     child: FilledButton.icon(
//                       onPressed: _openNewCampaign,
//                       icon: const Icon(Icons.add),
//                       label: const Text(
//                         "Créer une campagne",
//                         style: TextStyle(fontWeight: FontWeight.w900),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//         body: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final isPhone = constraints.maxWidth < 600;
//               final contentMaxWidth = kIsWeb ? maxWidth : double.infinity;

//               return Center(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(maxWidth: contentMaxWidth),
//                   child: FutureBuilder<List<dynamic>>(
//                     future: _future,
//                     builder: (context, snap) {
//                       if (snap.connectionState != ConnectionState.done) {
//                         return const Center(child: CircularProgressIndicator());
//                       }
//                       if (snap.hasError) {
//                         return Center(
//                           child: Padding(
//                             padding: const EdgeInsets.all(16),
//                             child: Text(
//                               "Erreur : ${snap.error}",
//                               style: const TextStyle(color: Colors.red),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         );
//                       }

//                       final items = (snap.data ?? []).cast<dynamic>();

//                       if (items.isEmpty) {
//                         return _emptyState(isMobile: isPhone);
//                       }

//                       return RefreshIndicator(
//                         onRefresh: () async => _refresh(),
//                         child: ListView.builder(
//                           padding: EdgeInsets.fromLTRB(16, 14, 16, kIsWeb ? 16 : 84),
//                           itemCount: items.length,
//                           itemBuilder: (_, i) {
//                             final c = (items[i] as Map).cast<String, dynamic>();
//                             return _campaignCard(c, isMobile: isMobile);
//                           },
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _emptyState({required bool isMobile}) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               height: 86,
//               width: 86,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF6D28D9).withOpacity(0.08),
//                 borderRadius: BorderRadius.circular(22),
//               ),
//               child: const Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF6D28D9)),
//             ),
//             const SizedBox(height: 14),
//             const Text(
//               "Vous n’avez aucune campagne pour le moment",
//               style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "Créez une nouvelle campagne puis attendez l’approbation de l’administrateur.",
//               style: TextStyle(color: Colors.black54, height: 1.4),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 18),

//             // ✅ على الهاتف: أزرار بعرض كامل
//             if (isMobile) ...[
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: FilledButton.icon(
//                   onPressed: _openNewCampaign,
//                   icon: const Icon(Icons.add),
//                   label: const Text("Créer une campagne"),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: OutlinedButton.icon(
//                   onPressed: _openPublicCampaigns,
//                   icon: const Icon(Icons.public),
//                   label: const Text("Voir les campagnes publiques"),
//                 ),
//               ),
//             ] else ...[
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: [
//                   FilledButton.icon(
//                     onPressed: _openNewCampaign,
//                     icon: const Icon(Icons.add),
//                     label: const Text("Créer une campagne"),
//                   ),
//                   OutlinedButton.icon(
//                     onPressed: _openPublicCampaigns,
//                     icon: const Icon(Icons.public),
//                     label: const Text("Voir les campagnes publiques"),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _campaignCard(Map<String, dynamic> c, {required bool isMobile}) {
//     final int id = int.tryParse(c["id"]?.toString() ?? "0") ?? 0;
//     final String title = (c["title"] ?? "").toString();
//     final String status = (c["status"] ?? "PENDING").toString();

//     final double goal = _d(c["goal_amount"]);
//     final double collected = _d(c["collected_amount"]);
//     final double progress = goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;

//     final String reason = (c["rejection_reason"] ?? "").toString().trim();

//     final bool canEditOrDelete = !_isApproved(status);
//     final statusColor = _statusColor(status);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: Colors.black.withOpacity(0.06)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 18,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ===== title + status =====
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 16.5,
//                     fontWeight: FontWeight.w900,
//                     height: 1.15,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(999),
//                   border: Border.all(color: statusColor.withOpacity(0.22)),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(_statusIcon(status), size: 16, color: statusColor),
//                     const SizedBox(width: 6),
//                     Text(
//                       _statusText(status),
//                       style: TextStyle(
//                         color: statusColor,
//                         fontWeight: FontWeight.w900,
//                         fontSize: 12.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // ===== progress =====
//           ClipRRect(
//             borderRadius: BorderRadius.circular(999),
//             child: LinearProgressIndicator(
//               value: progress,
//               minHeight: 10,
//               backgroundColor: const Color(0xFFF2F4F9),
//             ),
//           ),

//           const SizedBox(height: 10),

//           // ===== stats =====
//           Row(
//             children: [
//               Expanded(
//                 child: _statTile(
//                   title: "Objectif",
//                   value: _money(goal),
//                   icon: Icons.flag_outlined,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _statTile(
//                   title: "Collecté",
//                   value: _money(collected),
//                   icon: Icons.savings_outlined,
//                 ),
//               ),
//             ],
//           ),

//           // ===== rejection reason =====
//           if (status.toUpperCase() == "REJECTED") ...[
//             const SizedBox(height: 10),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFDC2626).withOpacity(0.06),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.18)),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Icon(Icons.info_outline, color: Color(0xFFDC2626)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "Raison du rejet : ${reason.isEmpty ? 'Aucune raison fournie' : reason}",
//                       style: const TextStyle(color: Color(0xFFB91C1C), height: 1.35),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],

//           const SizedBox(height: 12),

//           // ===== actions =====
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton.icon(
//                   icon: const Icon(Icons.edit_outlined),
//                   label: const Text("Modifier"),
//                   onPressed: canEditOrDelete ? () => _openEdit(c) : null,
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: OutlinedButton.icon(
//                   icon: const Icon(Icons.delete_outline),
//                   label: const Text("Supprimer"),
//                   onPressed: (canEditOrDelete && id != 0) ? () => _deleteCampaign(id) : null,
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     foregroundColor: Colors.red,
//                     side: const BorderSide(color: Colors.red),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           if (!canEditOrDelete) ...[
//             const SizedBox(height: 10),
//             const Text(
//               "Impossible de modifier/supprimer une campagne après approbation.",
//               style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _statTile({
//     required String title,
//     required String value,
//     required IconData icon,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF6F7FB),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.black.withOpacity(0.06)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 34,
//             width: 34,
//             decoration: BoxDecoration(
//               color: const Color(0xFF6D28D9).withOpacity(0.10),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: Colors.black.withOpacity(0.55),
//                     fontSize: 12,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   value,
//                   style: const TextStyle(fontWeight: FontWeight.w900),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
