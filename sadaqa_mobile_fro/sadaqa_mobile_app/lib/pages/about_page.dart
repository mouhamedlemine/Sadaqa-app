import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");
    return token != null && token.isNotEmpty;
  }

  Future<void> _requireLoginThenGo(String routeName) async {
    final ok = await _isLoggedIn();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez vous connecter d'abord."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, "/login");
      return;
    }

    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    String t(String ar, String fr, String en) {
      if (lang == 'ar') return ar;
      if (lang == 'fr') return fr;
      return en;
    }

    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(t("من نحن", "À propos", "About")),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ✅ HERO (Pro)
            _HeroPro(
              isAr: isAr,
              title: t("منصة صدقة", "Plateforme Sadaqa", "Sadaqa Platform"),
              subtitle: t(
                "نقرب الخير للناس عبر تبرعات شفافة وآمنة.",
                "Nous rapprochons la solidarité grâce à des dons transparents et sécurisés.",
                "We bring giving closer through transparent and secure donations.",
              ),
              badge: t("DevSecOps", "DevSecOps", "DevSecOps"),
              primaryText: t("استكشاف الحملات", "Découvrir les campagnes", "Explore campaigns"),
              secondaryText: t("كيف تعمل؟", "Comment ça marche", "How it works"),
              onPrimary: () => _requireLoginThenGo("/campaigns"),
              onSecondary: () => Navigator.pushNamed(context, "/how-it-works"),
            ),

            const SizedBox(height: 16),

            // ✅ STATS -> Grid on mobile
            _StatsGrid(
              isMobile: isMobile,
              children: [
                _StatCardPro(
                  icon: Icons.verified_user_outlined,
                  title: t("أمان", "Sécurité", "Security"),
                  value: t("مُدمج", "Intégrée", "Built-in"),
                ),
                _StatCardPro(
                  icon: Icons.visibility_outlined,
                  title: t("شفافية", "Transparence", "Transparency"),
                  value: t("واضحة", "Claire", "Clear"),
                ),
                _StatCardPro(
                  icon: Icons.flash_on_outlined,
                  title: t("سرعة", "Rapidité", "Speed"),
                  value: t("مباشرة", "Instant", "Instant"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SectionCardPro(
              title: t("رسالتنا", "Notre mission", "Our mission"),
              icon: Icons.flag_outlined,
              child: Text(
                t(
                  "نهدف إلى تسهيل التبرع ومساعدة المحتاجين عبر منصة موثوقة تجمع بين السهولة والشفافية والأمان، مع متابعة الحملات لحظة بلحظة.",
                  "Faciliter le don et soutenir les personnes dans le besoin via une plateforme fiable, combinant simplicité, transparence et sécurité, avec un suivi en temps réel.",
                  "To make donating easy and reliable through a platform that combines simplicity, transparency, and security, with real-time campaign tracking.",
                ),
                style: const TextStyle(fontSize: 15.5, height: 1.6),
                textAlign: isAr ? TextAlign.right : TextAlign.left,
              ),
            ),

            const SizedBox(height: 16),

            _SectionCardPro(
              title: t("قيمنا", "Nos valeurs", "Our values"),
              icon: Icons.stars_outlined,
              child: Column(
                children: [
                  _ValueTilePro(
                    icon: Icons.lock_outline,
                    title: t("الأمان أولاً", "Sécurité d’abord", "Security first"),
                    subtitle: t(
                      "حماية الحسابات والبيانات واعتماد أفضل الممارسات.",
                      "Protection des comptes et des données, meilleures pratiques.",
                      "Protect accounts and data with best practices.",
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ValueTilePro(
                    icon: Icons.fact_check_outlined,
                    title: t("الشفافية", "Transparence", "Transparency"),
                    subtitle: t(
                      "معلومات واضحة عن الحملات والتقدم والتقارير.",
                      "Infos claires sur les campagnes, progrès et rapports.",
                      "Clear info on campaigns, progress and reporting.",
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ValueTilePro(
                    icon: Icons.volunteer_activism_outlined,
                    title: t("الأثر الحقيقي", "Impact réel", "Real impact"),
                    subtitle: t(
                      "نركز على دعم الحالات الأكثر احتياجاً بفعالية.",
                      "Priorité aux cas les plus urgents et efficaces.",
                      "We focus on helping urgent cases effectively.",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCardPro(
              title: t("كيف تعمل المنصة؟", "Comment ça marche ?", "How it works?"),
              icon: Icons.route_outlined,
              child: Column(
                children: [
                  _StepTilePro(
                    step: "1",
                    title: t("اختر حملة", "Choisissez une campagne", "Choose a campaign"),
                    subtitle: t(
                      "تصفح الحملات واختر الحالة المناسبة.",
                      "Parcourez et sélectionnez une cause.",
                      "Browse and pick a cause.",
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StepTilePro(
                    step: "2",
                    title: t("تبرع بأمان", "Donnez en toute sécurité", "Donate securely"),
                    subtitle: t(
                      "عملية تبرع بسيطة وآمنة.",
                      "Paiement simple et sécurisé.",
                      "Simple and secure donation flow.",
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StepTilePro(
                    step: "3",
                    title: t("تابع الأثر", "Suivez l’impact", "Track impact"),
                    subtitle: t(
                      "شاهد التقدم وتحديثات الحملة.",
                      "Consultez l’avancement et les mises à jour.",
                      "See progress and campaign updates.",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ CTA bottom (Pro)
            _CTAPro(
              isAr: isAr,
              title: t("جاهز للتبرع؟", "Prêt à donner ?", "Ready to donate?"),
              subtitle: t(
                "ابدأ الآن وساهم في تغيير حياة شخص.",
                "Commencez maintenant et changez une vie.",
                "Start now and change someone’s life.",
              ),
              buttonText: t("استكشاف الحملات", "Explorer", "Explore"),
              onPressed: () => _requireLoginThenGo("/campaigns"),
            ),

            const SizedBox(height: 14),

            Center(
              child: Text(
                t(
                  "© Sadaqa — منصة تبرعات آمنة وشفافة",
                  "© Sadaqa — Dons sécurisés et transparents",
                  "© Sadaqa — Secure & transparent donations",
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- PRO UI Widgets -------------------- */

class _HeroPro extends StatelessWidget {
  const _HeroPro({
    required this.isAr,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.primaryText,
    required this.secondaryText,
    required this.onPrimary,
    required this.onSecondary,
  });

  final bool isAr;
  final String title;
  final String subtitle;
  final String badge;
  final String primaryText;
  final String secondaryText;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: isAr ? Alignment.topRight : Alignment.topLeft,
          end: isAr ? Alignment.bottomLeft : Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.95),
            const Color(0xFF111827),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 26,
            offset: Offset(0, 16),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              _BadgePro(text: badge),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.volunteer_activism, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: isAr ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.12,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: isAr ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 14.8,
              height: 1.6,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 14),

          // ✅ Buttons responsive (wrap)
          Wrap(
            alignment: isAr ? WrapAlignment.end : WrapAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: ElevatedButton.icon(
                  onPressed: onPrimary,
                  icon: const Icon(Icons.explore_outlined),
                  label: Text(primaryText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: OutlinedButton.icon(
                  onPressed: onSecondary,
                  icon: const Icon(Icons.info_outline),
                  label: Text(secondaryText),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.55)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgePro extends StatelessWidget {
  const _BadgePro({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.isMobile, required this.children});
  final bool isMobile;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.7,
        children: children,
      );
    }
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 12),
        Expanded(child: children[1]),
        const SizedBox(width: 12),
        Expanded(child: children[2]),
      ],
    );
  }
}

class _StatCardPro extends StatelessWidget {
  const _StatCardPro({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.primaryColor),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _SectionCardPro extends StatelessWidget {
  const _SectionCardPro({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ValueTilePro extends StatelessWidget {
  const _ValueTilePro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.primaryColor.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.2)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.8, height: 1.35, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTilePro extends StatelessWidget {
  const _StepTilePro({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final String step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              step,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: theme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CTAPro extends StatelessWidget {
  const _CTAPro({
    required this.isAr,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  final bool isAr;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: isAr ? Alignment.topRight : Alignment.topLeft,
          end: isAr ? Alignment.bottomLeft : Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.72),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: isAr ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: isAr ? TextAlign.right : TextAlign.left,
            style: TextStyle(color: Colors.white.withOpacity(0.92), height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
