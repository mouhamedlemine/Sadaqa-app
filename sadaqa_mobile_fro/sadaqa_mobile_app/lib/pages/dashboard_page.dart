import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ✅ الحل النهائي لفتح Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  // ✅ Confirmation dialog before logout
  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Confirmation",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            "Êtes-vous sûr de vouloir vous déconnecter ?",
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Annuler",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Se déconnecter",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    return Scaffold(
      key: _scaffoldKey, // ✅ مهم
      backgroundColor: const Color(0xFFF6F7FB),

      // ✅ Drawer (Mobile)
      drawer: isMobile
          ? _MobileDrawer(
              onLogout: () => _confirmLogout(context),
            )
          : null,

      body: SafeArea(
        child: Column(
          children: [
            _TopNav(
              onLogout: () => _confirmLogout(context),
              isMobile: isMobile,
              onOpenDrawer: isMobile
                  ? () => _scaffoldKey.currentState?.openDrawer() // ✅ الحل
                  : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        const _HeroCard(),
                        const SizedBox(height: 18),

                        // ✅ Responsive cards
                        LayoutBuilder(
                          builder: (context, c) {
                            final m = c.maxWidth < 768;

                            if (m) {
                              return const Column(
                                children: [
                                  _MiniInfoCard(
                                    icon: Icons.verified_rounded,
                                    title: "Transparence",
                                    subtitle: "Suivi clair des dons",
                                  ),
                                  SizedBox(height: 12),
                                  _MiniInfoCard(
                                    icon: Icons.lock_rounded,
                                    title: "Sécurité",
                                    subtitle: "Paiements protégés",
                                  ),
                                  SizedBox(height: 12),
                                  _MiniInfoCard(
                                    icon: Icons.flash_on_rounded,
                                    title: "Rapidité",
                                    subtitle: "Don en quelques secondes",
                                  ),
                                ],
                              );
                            }

                            return const Row(
                              children: [
                                Expanded(
                                  child: _MiniInfoCard(
                                    icon: Icons.verified_rounded,
                                    title: "Transparence",
                                    subtitle: "Suivi clair des dons",
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _MiniInfoCard(
                                    icon: Icons.lock_rounded,
                                    title: "Sécurité",
                                    subtitle: "Paiements protégés",
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _MiniInfoCard(
                                    icon: Icons.flash_on_rounded,
                                    title: "Rapidité",
                                    subtitle: "Don en quelques secondes",
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// MOBILE DRAWER
// =========================
class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Logo(),
              ),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.explore),
              title: const Text("Explorer"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/volunteer");
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text("Faire un don"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/campaigns");
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text("Préférés"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/favorites");
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("Comment ça marche"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/how-it-works");
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Mon compte"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/my-campaigns");
              },
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    "Déconnexion",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// TOP NAV
// =========================
class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.onLogout,
    required this.isMobile,
    required this.onOpenDrawer,
  });

  final VoidCallback onLogout;
  final bool isMobile;
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    // ✅ Mobile: AppBar-like
    if (isMobile) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onOpenDrawer,
              icon: const Icon(Icons.menu),
            ),
            const _Logo(),
            const Spacer(),
            IconButton(
              tooltip: "Déconnexion",
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      );
    }

    // ✅ Desktop / Tablet: original layout
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              _PillButton(
                text: "Déconnexion",
                icon: Icons.logout_rounded,
                onTap: onLogout,
                filled: false,
              ),
              const SizedBox(width: 10),
              _PillButton(
                text: "Mon compte",
                icon: Icons.person_rounded,
                onTap: () => Navigator.pushNamed(context, "/my-campaigns"),
                filled: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SearchBox(
                  hint: "Rechercher…",
                  onSubmitted: (v) {},
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  _NavLink(
                    text: "Comment ça marche",
                    onTap: () => Navigator.pushNamed(context, "/how-it-works"),
                  ),
                  _NavLink(
                    text: "Explorer",
                    onTap: () => Navigator.pushNamed(context, "/volunteer"),
                    isActive: true,
                  ),
                  _NavLink(
                    text: "Faire un don",
                    onTap: () => Navigator.pushNamed(context, "/campaigns"),
                  ),
                  _NavLink(
                    text: "Préférés",
                    onTap: () => Navigator.pushNamed(context, "/favorites"),
                  ),
                  const SizedBox(width: 14),
                  const _Logo(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// HERO CARD
// =========================
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final isSmall = c.maxWidth < 860;

          final image = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Image.network(
                  "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=1400&q=80",
                  height: isSmall ? 240 : 360,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      "Urgent",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          );

          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                "Soutenez les personnes dans le besoin",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: isSmall ? 26 : 36,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Une plateforme qui relie les donateurs aux campagnes caritatives\n"
                "vérifiées, en toute transparence.\n"
                "Donnez rapidement et suivez l'impact de votre don.",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: isSmall ? 14.5 : 15.5,
                  height: 1.55,
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                width: isSmall ? double.infinity : null,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, "/campaigns"),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    "Explorer les campagnes",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                image,
                const SizedBox(height: 16),
                text,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 6, child: image),
              const SizedBox(width: 18),
              Expanded(flex: 5, child: text),
            ],
          );
        },
      ),
    );
  }
}

// =========================
// SMALL INFO CARDS
// =========================
class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6D28D9)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
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

// =========================
// UI ATOMS
// =========================
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint, required this.onSubmitted});
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.search_rounded, color: Colors.black.withOpacity(0.45)),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.text,
    required this.onTap,
    this.isActive = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(0xFF2563EB)
        : Colors.black.withOpacity(0.70);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Sadaqa",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.volunteer_activism, color: Color(0xFF6D28D9)),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? const Color(0xFF2563EB) : Colors.white;
    final fg = filled ? Colors.white : Colors.black87;
    final border = BorderSide(color: Colors.black.withOpacity(0.12));

    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: fg),
        label: Text(
          text,
          style: TextStyle(color: fg, fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: filled ? BorderSide.none : border,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
