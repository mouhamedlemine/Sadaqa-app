import 'package:flutter/material.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == "ar";

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FF),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: const [
                _TopHeader(),
                SizedBox(height: 16),
                _Hero(),
                SizedBox(height: 22),
                _StepsSection(),
                SizedBox(height: 22),
                _FeaturesSection(),
                SizedBox(height: 22),
                _SecuritySection(),
                SizedBox(height: 22),
                _FaqSection(),
                SizedBox(height: 26),
                _CallToAction(),
                SizedBox(height: 24),
                _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= HEADER =================
class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == "ar";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              IconButton(
                tooltip: isArabic ? "Retour" : "Retour",
                onPressed: () => Navigator.pop(context),
                icon: Icon(isArabic ? Icons.arrow_back : Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              const Text(
                "Comment ça marche",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              const _ChipInfo(
                icon: Icons.verified_user_outlined,
                text: "Transparence",
              ),
              const SizedBox(width: 8),
              const _ChipInfo(
                icon: Icons.lock_outline,
                text: "Sécurité",
              ),
              const SizedBox(width: 8),
              const _ChipInfo(
                icon: Icons.speed_outlined,
                text: "Rapidité",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ================= HERO =================
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Votre chemin pour donner\nsimplement et en toute transparence",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Nous vous aidons à accéder à des campagnes certifiées, à effectuer des dons rapidement, puis à suivre l’impact étape par étape.",
                          style: TextStyle(color: Colors.grey.shade700, height: 1.6),
                        ),
                        const SizedBox(height: 14),
                        const Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MiniCard(
                              icon: Icons.search,
                              title: "Explorer",
                              subtitle: "Campagnes & catégories",
                            ),
                            _MiniCard(
                              icon: Icons.volunteer_activism,
                              title: "Donner",
                              subtitle: "En toute sécurité",
                            ),
                            _MiniCard(
                              icon: Icons.track_changes,
                              title: "Suivre l’impact",
                              subtitle: "Mises à jour claires",
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text("Retour à l’accueil"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text("Découvrir les campagnes"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Image.network(
                          "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=1400",
                          height: 320,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 16,
                          bottom: 14,
                          left: 16,
                          child: _OverlayNote(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayNote extends StatelessWidget {
  const _OverlayNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Nous présentons des campagnes certifiées et offrons une expérience de don claire avec un suivi de l’impact.",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= STEPS =================
class _StepsSection extends StatelessWidget {
  const _StepsSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: "Étapes d’utilisation",
      subtitle: "3 étapes simples, de la découverte au suivi de l’impact",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: const [
          _StepCard(
            number: "1",
            title: "Découvrir les campagnes",
            desc: "Parcourez les catégories et choisissez une campagne adaptée à votre objectif.",
            icon: Icons.search,
          ),
          _StepCard(
            number: "2",
            title: "Effectuer un don",
            desc: "Faites un don rapidement grâce à des options de paiement sécurisées.",
            icon: Icons.payments_outlined,
          ),
          _StepCard(
            number: "3",
            title: "Suivre l’impact",
            desc: "Consultez les mises à jour de l’état du don et de la campagne.",
            icon: Icons.track_changes,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.desc,
    required this.icon,
  });

  final String number;
  final String title;
  final String desc;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 6),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: Colors.black54, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= FEATURES =================
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: "Pourquoi notre plateforme ?",
      subtitle: "Des avantages qui rendent l’expérience de don plus fiable et plus claire",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: const [
          _FeatureCard(
            icon: Icons.verified_outlined,
            title: "Campagnes certifiées",
            desc: "Nous affichons des campagnes fiables et vérifiées autant que possible.",
          ),
          _FeatureCard(
            icon: Icons.receipt_long_outlined,
            title: "Reçu & traçabilité",
            desc: "Vous pouvez enregistrer, confirmer et suivre les informations du don.",
          ),
          _FeatureCard(
            icon: Icons.support_agent_outlined,
            title: "Support utilisateur",
            desc: "Une interface claire et une expérience simple et rapide.",
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.desc});
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: Colors.black54, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SECURITY =================
class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: "Sécurité et confidentialité",
      subtitle: "Nous nous concentrons sur la protection des comptes et des données sensibles",
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12.withOpacity(0.06)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bullet(icon: Icons.lock_outline, text: "Sessions sécurisées via des jetons (JWT)."),
            SizedBox(height: 10),
            _Bullet(icon: Icons.security_outlined, text: "Contrôle d’accès aux pages sensibles."),
            SizedBox(height: 10),
            _Bullet(icon: Icons.visibility_off_outlined, text: "Réduction de l’exposition des données utilisateur au maximum."),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
      ],
    );
  }
}

// ================= FAQ =================
class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: "Questions fréquentes",
      subtitle: "Réponses rapides aux questions les plus courantes",
      child: const Column(
        children: [
          _FaqItem(
            q: "Dois-je me connecter pour faire un don ?",
            a: "Oui, pour confirmer votre identité, enregistrer l’historique des dons et assurer le suivi.",
          ),
          SizedBox(height: 10),
          _FaqItem(
            q: "Puis-je suivre l’impact du don ?",
            a: "Oui, l’état du don et les mises à jour de la campagne apparaîtront (selon les informations fournies par l’organisme).",
          ),
          SizedBox(height: 10),
          _FaqItem(
            q: "Mes données sont-elles protégées ?",
            a: "Nous appliquons les meilleures pratiques pour sécuriser la connexion et réduire la collecte de données.",
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: Colors.black54,
        iconColor: Colors.black87,
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w900)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                a,
                style: const TextStyle(color: Colors.black54, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= CTA =================
class _CallToAction extends StatelessWidget {
  const _CallToAction();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black12.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Prêt à commencer ?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      SizedBox(height: 6),
                      Text(
                        "Retournez à l’accueil, découvrez les campagnes, puis faites un don facilement.",
                        style: TextStyle(color: Colors.black54, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Retour"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= FOOTER =================
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Text(
            "© ${DateTime.now().year} - Plateforme de dons | Tous droits réservés",
            style: const TextStyle(color: Colors.black45),
          ),
        ),
      ),
    );
  }
}

// ================= SECTION WRAPPER =================
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
