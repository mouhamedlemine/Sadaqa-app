// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/locale_controller.dart';

import 'campaign_list_page.dart';
import 'how_it_works_page.dart';
import 'login_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.localeController,
  });

  final LocaleController localeController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ✅ مفتاح للـScaffold لفتح Drawer بشكل صحيح
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _activeSlide = 0;

  final _slides = const [
    _SlideData(
      imageUrl:
          "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=1600&q=80",
      badgeAr: "احتياج عاجل",
      badgeFr: "Urgent",
      captionAr: "كفالة يتيم في غزة",
      captionFr: "Parrainage d’un orphelin à Gaza",
    ),
    _SlideData(
      imageUrl:
          "https://images.unsplash.com/photo-1526256262350-7da7584cf5eb?w=1600",
      badgeAr: "مشروع",
      badgeFr: "Projet",
      captionAr: "سلال غذائية للأسر",
      captionFr: "Paniers alimentaires",
    ),
    _SlideData(
      imageUrl:
          "https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=1600",
      badgeAr: "تدخل سريع",
      badgeFr: "Aide rapide",
      captionAr: "دعم علاجي",
      captionFr: "Aide médicale",
    ),
  ];

  // =========================
  // ✅ Auth Guard
  // =========================
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");
    return token != null && token.isNotEmpty;
  }

  Future<void> _goToLogin(BuildContext context) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Veuillez vous connecter d'abord."),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // ✅ هذه هي الدالة التي تمنع فتح Explorer / campaigns إلا بعد Login
  Future<void> _openCampaignsGuarded() async {
    final ok = await _isLoggedIn();
    if (!mounted) return;

    if (!ok) {
      await _goToLogin(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CampaignListPage()),
    );
  }

  void _openHowItWorks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HowItWorksPage()),
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // ✅ NEW: فتح صفحة "من نحن"
  void _openAbout() {
    // الأفضل لأنك أضفت route في main.dart
    Navigator.pushNamed(context, "/about");

    // لو أردت بدون route:
    // Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FC),

      // ✅ Drawer للهاتف
      // ✅ تعديل مهم: Explorer يستدعي Guard بعد إغلاق الـDrawer
      drawer: isMobile
          ? _AppDrawer(
              isAr: isAr,
              onExplore: () async {
                Navigator.pop(context); // اغلاق drawer
                await _openCampaignsGuarded(); // ✅ لا يفتح إلا بعد Login
              },
              onHowItWorks: () {
                Navigator.pop(context);
                _openHowItWorks();
              },
              onAbout: () {
                Navigator.pop(context);
                _openAbout();
              },
              onLogin: () {
                Navigator.pop(context);
                _openLogin();
              },
              onToggleLang: () {
                Navigator.pop(context);
                widget.localeController.toggleArFr();
              },
            )
          : null,

      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              isAr: isAr,
              isMobile: isMobile,
              onToggleLang: widget.localeController.toggleArFr,
              onLogin: _openLogin,
              onGoHome: () => Navigator.popUntil(context, (r) => r.isFirst),

              // ✅ Explorer في TopBar محمي أيضاً
              onExplore: _openCampaignsGuarded,

              onHowItWorks: _openHowItWorks,

              // ✅ NEW
              onAbout: _openAbout,

              // ✅ فتح Drawer بالمفتاح
              onOpenDrawer: isMobile
                  ? () => _scaffoldKey.currentState?.openDrawer()
                  : null,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _HeroSection(
                        isAr: isAr,
                        slides: _slides,
                        activeIndex: _activeSlide,
                        onSlideChanged: (i) => setState(() => _activeSlide = i),

                        // ✅ زر "Découvrir les campagnes" محمي أيضاً
                        onExplore: _openCampaignsGuarded,
                      ),
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

// =================== DRAWER (Mobile) ===================
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.isAr,
    required this.onExplore,
    required this.onHowItWorks,
    required this.onAbout, // ✅ NEW
    required this.onLogin,
    required this.onToggleLang,
  });

  final bool isAr;
  final VoidCallback onExplore;
  final VoidCallback onHowItWorks;
  final VoidCallback onAbout; // ✅ NEW
  final VoidCallback onLogin;
  final VoidCallback onToggleLang;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: Text(
                isAr ? "صدقة" : "Sadaqa",
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Divider(height: 1),

            // ✅ Explorer guarded (لا يفتح إلا بعد تسجيل الدخول)
            ListTile(
              leading: const Icon(Icons.explore),
              title: Text(isAr ? "استكشف" : "Explorer"),
              onTap: onExplore,
            ),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(isAr ? "كيف يعمل" : "Comment ça marche"),
              onTap: onHowItWorks,
            ),

            // ✅ NEW: About
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(isAr ? "من نحن" : "À propos"),
              onTap: onAbout,
            ),

            ListTile(
              leading: const Icon(Icons.language),
              title: Text(isAr ? "تبديل اللغة" : "Changer la langue"),
              onTap: onToggleLang,
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isAr ? "تسجيل الدخول" : "Connexion"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== TOP BAR ===================
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isAr,
    required this.isMobile,
    required this.onToggleLang,
    required this.onLogin,
    required this.onGoHome,
    required this.onExplore,
    required this.onHowItWorks,
    required this.onAbout, // ✅ NEW
    required this.onOpenDrawer,
  });

  final bool isAr;
  final bool isMobile;
  final VoidCallback onToggleLang;
  final VoidCallback onLogin;
  final VoidCallback onGoHome;
  final VoidCallback onExplore;
  final VoidCallback onHowItWorks;
  final VoidCallback onAbout; // ✅ NEW
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black12.withOpacity(0.06)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (isMobile)
                  IconButton(
                    onPressed: onOpenDrawer,
                    icon: const Icon(Icons.menu),
                  ),

                InkWell(
                  onTap: onGoHome,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.volunteer_activism,
                          color: cs.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAr ? "صدقة" : "Sadaqa",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                if (!isMobile && MediaQuery.of(context).size.width > 780) ...[
                  _NavLink(
                    isAr: isAr,
                    textAr: "استكشف",
                    textFr: "Explorer",
                    onTap: onExplore, // ✅ guarded
                  ),
                  _NavLink(
                    isAr: isAr,
                    textAr: "كيف يعمل",
                    textFr: "Comment ça marche",
                    onTap: onHowItWorks,
                  ),
                  // ✅ NEW: About button on top bar
                  _NavLink(
                    isAr: isAr,
                    textAr: "من نحن",
                    textFr: "À propos",
                    onTap: onAbout,
                  ),
                ],

                const Spacer(),

                if (MediaQuery.of(context).size.width > 700)
                  SizedBox(
                    width: 320,
                    child: TextField(
                      textDirection:
                          isAr ? TextDirection.rtl : TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: isAr ? "بحث..." : "Rechercher...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF6F7FB),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                IconButton(
                  tooltip: isAr ? "تبديل اللغة" : "Changer la langue",
                  onPressed: onToggleLang,
                  icon: const Icon(Icons.language),
                ),

                const SizedBox(width: 6),

                ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 14,
                      vertical: 12,
                    ),
                  ),
                  child: Text(isAr ? "تسجيل الدخول" : "Connexion"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.isAr,
    required this.textAr,
    required this.textFr,
    required this.onTap,
  });

  final bool isAr;
  final String textAr;
  final String textFr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        isAr ? textAr : textFr,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// =================== HERO SECTION ===================
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.isAr,
    required this.slides,
    required this.activeIndex,
    required this.onSlideChanged,
    required this.onExplore,
  });

  final bool isAr;
  final List<_SlideData> slides;
  final int activeIndex;
  final ValueChanged<int> onSlideChanged;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 980;
    final isNarrow = w < 980;

    final title = isAr
        ? "ادعم المحتاجين\nساعد مجتمعك"
        : "Soutenez les plus démunis\nAidez votre communauté";
    final desc = isAr
        ? "نجمع العطاء الذي يغيّر حياة المحتاجين عبر حملات خيرية معتمدة وشفافة."
        : "Nous réunissons des dons qui changent des vies via des campagnes fiables et transparentes.";
    final btn = isAr ? "استكشاف الحملات" : "Découvrir les campagnes";

    final double titleSize = isMobile ? 26 : (isTablet ? 30 : 34);
    final double descSize = isMobile ? 14 : 14.5;

    final double sliderHeight = isMobile ? 300 : (isTablet ? 320 : 340);

    final textSide = Column(
      crossAxisAlignment:
          isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: isAr ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          desc,
          textAlign: isAr ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.7,
            fontSize: descSize,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: onExplore, // ✅ guarded
            icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward),
            label: Text(btn),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: isAr ? WrapAlignment.end : WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              icon: Icons.verified_user_outlined,
              text: isAr ? "شفافية" : "Transparence",
            ),
            _Pill(icon: Icons.lock_outline, text: isAr ? "أمان" : "Sécurité"),
            _Pill(icon: Icons.speed_outlined, text: isAr ? "سرعة" : "Rapidité"),
          ],
        ),
      ],
    );

    final sliderSide = _SliderCard(
      isAr: isAr,
      slides: slides,
      activeIndex: activeIndex,
      onSlideChanged: onSlideChanged,
      height: sliderHeight,
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  sliderSide,
                  const SizedBox(height: 16),
                  textSide,
                ] else ...[
                  textSide,
                  const SizedBox(height: 16),
                  sliderSide,
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: sliderSide),
                const SizedBox(width: 18),
                Expanded(child: textSide),
              ],
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// =================== SLIDER ===================
class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.isAr,
    required this.slides,
    required this.activeIndex,
    required this.onSlideChanged,
    required this.height,
  });

  final bool isAr;
  final List<_SlideData> slides;
  final int activeIndex;
  final ValueChanged<int> onSlideChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          SizedBox(
            height: height,
            child: PageView.builder(
              itemCount: slides.length,
              onPageChanged: onSlideChanged,
              itemBuilder: (_, i) => _SlideView(isAr: isAr, data: slides[i]),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.isAr, required this.data});
  final bool isAr;
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            data.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isAr ? Alignment.centerLeft : Alignment.centerRight,
                end: isAr ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: isAr ? null : 12,
          right: isAr ? 12 : null,
          child: _Badge(text: isAr ? data.badgeAr : data.badgeFr),
        ),
        Positioned(
          bottom: 14,
          left: 12,
          right: 12,
          child: _Caption(
            text: isAr ? data.captionAr : data.captionFr,
            isAr: isAr,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.text, required this.isAr});
  final String text;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          shadows: [Shadow(blurRadius: 18, color: Colors.black54)],
        ),
      ),
    );
  }
}

class _SlideData {
  final String imageUrl;
  final String badgeAr;
  final String badgeFr;
  final String captionAr;
  final String captionFr;

  const _SlideData({
    required this.imageUrl,
    required this.badgeAr,
    required this.badgeFr,
    required this.captionAr,
    required this.captionFr,
  });
}
