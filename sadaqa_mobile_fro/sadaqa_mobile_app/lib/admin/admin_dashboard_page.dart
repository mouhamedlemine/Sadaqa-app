// lib/admin/admin_dashboard_page.dart
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == "ar";

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FF),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            isAr ? "لوحة تحكم المشرف" : "Tableau de bord Admin",
            style: const TextStyle(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(isAr: isAr),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _AdminTile(
                      title: isAr ? "الحملات" : "Campagnes",
                      subtitle: isAr ? "قبول/رفض/تعطيل" : "Valider / Refuser",
                      icon: Icons.campaign,
                      onTap: () {
                        // TODO: Navigate to manage campaigns
                      },
                    ),
                    _AdminTile(
                      title: isAr ? "التبرعات" : "Dons",
                      subtitle: isAr ? "عرض وتتبع العمليات" : "Suivi des paiements",
                      icon: Icons.payments,
                      onTap: () {
                        // TODO
                      },
                    ),
                    _AdminTile(
                      title: isAr ? "المنظمات" : "Organisations",
                      subtitle: isAr ? "مراجعة الطلبات" : "Vérifier les demandes",
                      icon: Icons.apartment,
                      onTap: () {
                        // TODO
                      },
                    ),
                    _AdminTile(
                      title: isAr ? "المستخدمون" : "Utilisateurs",
                      subtitle: isAr ? "إدارة الحسابات" : "Gestion des comptes",
                      icon: Icons.people,
                      onTap: () {
                        // TODO
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isAr;
  const _Header({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? "مرحبًا بك" : "Bienvenue",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? "تحكم في الحملات والتبرعات والطلبات"
                      : "Gérez campagnes, dons et demandes",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _AdminTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
