// lib/pages/login_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/auth_service.dart';
import '../services/organization_service.dart';
import '../config/api_config.dart';

import 'campaign_list_page.dart';
import 'my_campaigns_page.dart';

import '../utils/web.dart' as web;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  late final OrganizationService _orgService =
      OrganizationService(ApiConfig.baseUrl);

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  // USER fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // ORG fields
  final _orgNameController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  final _orgAddressController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage; // ✅ إضافة متغير للرسائل الناجحة

  // account type
  String _registerType = 'USER';

  // show/hide password
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      web.addFacebookSuccessListener((token) async {
        await _handleFacebookTokenLogin(token);
      });

      web.addFacebookFailureListener(() {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Échec de la connexion via Facebook';
        });
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _orgNameController.dispose();
    _orgPhoneController.dispose();
    _orgAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // =========================
  // Redirect after login
  // =========================
  Future<void> _redirectAfterLogin() async {
    final me = await _authService.getCurrentUser();

    if (me == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getLocalizedMessage('user_info_error');
      });
      return;
    }

    final role = me['role']; // DONOR / ORG / ADMIN
    final orgStatus = me['org_status']; // PENDING / APPROVED / REJECTED

    if (!mounted) return;

    if (role == 'ADMIN') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CampaignListPage()),
      );
      return;
    }

    if (role == 'ORG') {
      if (orgStatus == 'APPROVED') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyCampaignsPage()),
        );
      } else {
        final msg = (orgStatus == 'REJECTED')
            ? "Le compte de l'organisation a été refusé.\nVeuillez vérifier les informations et renvoyer."
            : "Le compte de l'organisation est en cours de vérification.\nVous serez notifié après approbation.";

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(orgStatus == 'REJECTED'
                ? 'Compte refusé'
                : 'En cours de vérification'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("D'accord"),
              ),
            ],
          ),
        );
      }
      return;
    }

    // DONOR/USER -> dashboard
    Navigator.pushReplacementNamed(context, "/dashboard");
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _successMessage = null; // ✅ مسح رسالة النجاح أيضًا
      if (!_isLoginMode) _registerType = 'USER';
    });
  }

  // ✅ دالة لترجمة الرسائل حسب لغة الواجهة
  String _getLocalizedMessage(String key) {
    final isArabic = Localizations.localeOf(context).languageCode == "ar";
    
    final messages = {
      'account_not_active': isArabic 
          ? 'حسابك غير مفعّل بعد. يرجى التحقق من بريدك الإلكتروني.'
          : "Votre compte n'est pas encore activé. Vérifiez votre e-mail.",
      'invalid_credentials': isArabic
          ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
          : "E-mail ou mot de passe incorrect.",
      'already_exists': isArabic
          ? 'هذا البريد الإلكتروني أو اسم المستخدم مستخدم من قبل.'
          : "Cet e-mail ou ce nom d'utilisateur est déjà utilisé.",
      'fill_required': isArabic
          ? 'يرجى ملء جميع الحقول المطلوبة.'
          : "Veuillez remplir tous les champs obligatoires.",
      'password_mismatch': isArabic
          ? 'كلمة المرور والتأكيد غير متطابقين.'
          : "Le mot de passe et la confirmation ne correspondent pas.",
      'enter_name': isArabic
          ? 'يرجى إدخال الاسم الأول والأخير.'
          : "Veuillez saisir le prénom et le nom.",
      'org_name_required': isArabic
          ? 'اسم المنظمة مطلوب.'
          : "Le nom de l'organisation est obligatoire.",
      'user_created': isArabic
          ? 'تم إنشاء الحساب بنجاح.\nيرجى التحقق من بريدك الإلكتروني لتفعيل الحساب.'
          : "Compte créé avec succès.\nVérifiez votre e-mail pour activer le compte.",
      'org_created': isArabic
          ? 'تم تسجيل المنظمة بنجاح.\nيرجى التحقق من بريدك الإلكتروني أولاً.\nثم سيبقى الحساب قيد المراجعة حتى موافقة المسؤول.'
          : "Organisation enregistrée avec succès.\nVérifiez votre e-mail d'abord.\nEnsuite, le compte restera en cours de vérification jusqu'à l'approbation de l'administrateur.",
      'user_info_error': isArabic
          ? 'تعذر استرجاع معلومات المستخدم.'
          : "Impossible de récupérer les informations de l'utilisateur.",
      'unexpected_error': isArabic
          ? 'خطأ غير متوقع: '
          : "Erreur inattendue : ",
    };
    
    return messages[key] ?? key;
  }

  String _humanizeAuthError(String error) {
    final e = error.toLowerCase();
    if (e.contains('no active account') || e.contains('non activ') || e.contains('غير مفعّل')) {
      return _getLocalizedMessage('account_not_active');
    }
    if (e.contains('invalid') || e.contains('incorrect') || e.contains('wrong') || e.contains('غير صحيح')) {
      return _getLocalizedMessage('invalid_credentials');
    }
    if (e.contains('already exists') || e.contains('unique') || e.contains('مستخدم من قبل')) {
      return _getLocalizedMessage('already_exists');
    }
    return error;
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null; // ✅ مسح الرسائل السابقة
    });

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final orgName = _orgNameController.text.trim();
    final orgPhone = _orgPhoneController.text.trim();
    final orgAddress = _orgAddressController.text.trim();

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLoginMode && username.isEmpty)) {
      setState(() {
        _errorMessage = _getLocalizedMessage('fill_required');
        _isLoading = false;
      });
      return;
    }

    if (!_isLoginMode) {
      if (password != confirmPassword) {
        setState(() {
          _errorMessage = _getLocalizedMessage('password_mismatch');
          _isLoading = false;
        });
        return;
      }

      if (_registerType == 'USER') {
        if (firstName.isEmpty || lastName.isEmpty) {
          setState(() {
            _errorMessage = _getLocalizedMessage('enter_name');
            _isLoading = false;
          });
          return;
        }
      } else {
        if (orgName.isEmpty) {
          setState(() {
            _errorMessage = _getLocalizedMessage('org_name_required');
            _isLoading = false;
          });
          return;
        }
      }
    }

    try {
      String? error;

      if (_isLoginMode) {
        error = await _authService.login(email: email, password: password);

        if (!mounted) return;

        if (error == null) {
          await _redirectAfterLogin();
        } else {
          setState(() => _errorMessage = _humanizeAuthError(error!));
        }
      } else {
        if (_registerType == 'USER') {
          error = await _authService.register(
            email: email,
            username: username,
            firstName: firstName,
            lastName: lastName,
            password: password,
          );
        } else {
          error = await _orgService.registerOrg(
            email: email,
            username: username,
            password: password,
            name: orgName,
            phone: orgPhone,
            address: orgAddress,
          );
        }

        if (!mounted) return;

        if (error == null) {
          setState(() {
            // ✅ استخدام الرسائل المترجمة
            _successMessage = (_registerType == 'USER')
                ? _getLocalizedMessage('user_created')
                : _getLocalizedMessage('org_created');
            _isLoginMode = true;
          });
        } else {
          setState(() => _errorMessage = _humanizeAuthError(error!));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _getLocalizedMessage('unexpected_error') + e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final String? error = await _authService.loginWithGoogle();

    if (!mounted) return;

    if (error == null) {
      await _redirectAfterLogin();
    } else {
      setState(() => _errorMessage = _humanizeAuthError(error));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loginWithFacebook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    if (kIsWeb) {
      web.callFacebookLoginJS();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "La connexion Facebook est activée uniquement sur le Web.";
      });
    }
  }

  Future<void> _handleFacebookTokenLogin(String token) async {
    final String? error = await _authService.loginWithFacebookToken(token);

    if (!mounted) return;

    if (error == null) {
      await _redirectAfterLogin();
    } else {
      setState(() => _errorMessage = _humanizeAuthError(error));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _openForgotPassword() {
    Navigator.pushNamed(context, "/forgot-password");
  }

  // =========================
  // UI Helpers
  // =========================
  InputDecoration _dec({
    required String label,
    required IconData icon,
    Widget? suffix,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.purple.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.purple, width: 1.6),
      ),
    );
  }

  Widget _gradientButton({
    required String text,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0xff7a1fa2), Color(0xffc04ee6)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.purple,
          backgroundColor: Colors.white.withOpacity(0.85),
          side: BorderSide(color: Colors.purple.withOpacity(0.18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ✅ صندوق رسائل الخطأ (أحمر)
  Widget _errorBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffffeef0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xfff5b5bd)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, height: 1.3))),
        ],
      ),
    );
  }

  // ✅ صندوق رسائل النجاح (أخضر)
  Widget _successBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff0fdf4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffbbf7d0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: Color(0xff16a34a), height: 1.3))),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xff7a1fa2), Color(0xffc04ee6)]),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 14),
        Text(
          _isLoginMode ? 'Connexion' : 'Créer un compte',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          _isLoginMode ? 'Bon retour' : 'Créez votre compte rapidement et commencez à donner',
          style: TextStyle(color: Colors.black.withOpacity(0.55)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, 18),
              )
            ],
          ),
          child: Padding(padding: const EdgeInsets.all(22), child: child),
        ),
      ),
    );
  }

  Widget _bg() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xfffde9ff), Color(0xfff7f0ff)],
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -50,
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withOpacity(0.10)),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -70,
          child: Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withOpacity(0.08)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == "ar";
    final titleBtn = _isLoginMode ? 'Se connecter' : "Créer le compte";

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            _bg(),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 22),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec(
                            label: 'E-mail',
                            hint: 'Entrez votre e-mail',
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (!_isLoginMode) ...[
                          DropdownButtonFormField<String>(
                            value: _registerType,
                            items: const [
                              DropdownMenuItem(value: 'USER', child: Text('Utilisateur')),
                              DropdownMenuItem(value: 'ORG', child: Text('Organisation')),
                            ],
                            onChanged: (v) => setState(() => _registerType = v ?? 'USER'),
                            decoration: _dec(label: 'Type de compte', icon: Icons.account_circle_outlined),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _usernameController,
                            decoration: _dec(
                              label: "Nom d'utilisateur",
                              hint: "Entrez votre nom d'utilisateur",
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_registerType == 'USER') ...[
                            TextField(
                              controller: _firstNameController,
                              decoration: _dec(label: 'Prénom', hint: 'Entrez votre prénom', icon: Icons.badge_outlined),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _lastNameController,
                              decoration: _dec(label: 'Nom', hint: 'Entrez votre nom', icon: Icons.family_restroom_outlined),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (_registerType == 'ORG') ...[
                            TextField(
                              controller: _orgNameController,
                              decoration: _dec(label: "Nom de l'organisation", hint: "Entrez le nom de l'organisation", icon: Icons.business_outlined),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _orgPhoneController,
                              decoration: _dec(label: "Téléphone (optionnel)", hint: "Entrez le téléphone", icon: Icons.phone_outlined),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _orgAddressController,
                              decoration: _dec(label: "Adresse (optionnel)", hint: "Entrez l'adresse", icon: Icons.location_on_outlined),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _dec(
                            label: 'Mot de passe',
                            hint: 'Entrez votre mot de passe',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),

                        if (_isLoginMode) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _openForgotPassword,
                              child: const Text("Mot de passe oublié ?", style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        if (!_isLoginMode)
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: _dec(
                              label: 'Confirmer le mot de passe',
                              hint: 'Retapez le mot de passe',
                              icon: Icons.lock_reset_outlined,
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                          ),

                        const SizedBox(height: 14),

                        // ✅ عرض صندوق الأخطاء إذا كان هناك خطأ
                        if (_errorMessage != null) ...[
                          _errorBox(_errorMessage!),
                          const SizedBox(height: 12),
                        ],

                        // ✅ عرض صندوق النجاح إذا كان هناك نجاح
                        if (_successMessage != null) ...[
                          _successBox(_successMessage!),
                          const SizedBox(height: 12),
                        ],

                        _gradientButton(
                          text: titleBtn,
                          onPressed: _isLoading ? null : _submit,
                          loading: _isLoading,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.black.withOpacity(0.10))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('ou', style: TextStyle(color: Colors.black.withOpacity(0.45))),
                            ),
                            Expanded(child: Divider(color: Colors.black.withOpacity(0.10))),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _socialButton(
                          icon: Icons.g_mobiledata,
                          text: 'Se connecter avec Google',
                          onTap: _isLoading ? null : _loginWithGoogle,
                        ),
                        const SizedBox(height: 10),
                        _socialButton(
                          icon: Icons.facebook,
                          text: 'Se connecter avec Facebook',
                          onTap: _isLoading ? null : _loginWithFacebook,
                        ),

                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: _isLoading ? null : _toggleMode,
                          child: Text(
                            _isLoginMode
                                ? "Vous n'avez pas de compte ? Créer un compte"
                                : "Vous avez déjà un compte ? Se connecter",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
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



// // lib/pages/login_page.dart
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

// import '../services/auth_service.dart';
// import '../services/organization_service.dart';
// import '../config/api_config.dart';

// import 'campaign_list_page.dart';
// import 'my_campaigns_page.dart';

// import '../utils/web.dart' as web;

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _authService = AuthService();
//   late final OrganizationService _orgService =
//       OrganizationService(ApiConfig.baseUrl);

//   final _emailController = TextEditingController();
//   final _usernameController = TextEditingController();

//   // USER fields
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();

//   // ORG fields
//   final _orgNameController = TextEditingController();
//   final _orgPhoneController = TextEditingController();
//   final _orgAddressController = TextEditingController();

//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   bool _isLoginMode = true;
//   bool _isLoading = false;
//   String? _errorMessage;

//   // account type
//   String _registerType = 'USER';

//   // show/hide password
//   bool _obscurePassword = true;
//   bool _obscureConfirm = true;

//   @override
//   void initState() {
//     super.initState();

//     if (kIsWeb) {
//       web.addFacebookSuccessListener((token) async {
//         await _handleFacebookTokenLogin(token);
//       });

//       web.addFacebookFailureListener(() {
//         if (!mounted) return;
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Échec de la connexion via Facebook';
//         });
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _usernameController.dispose();
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _orgNameController.dispose();
//     _orgPhoneController.dispose();
//     _orgAddressController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   // =========================
//   // Redirect after login
//   // =========================
//   Future<void> _redirectAfterLogin() async {
//     final me = await _authService.getCurrentUser();

//     if (me == null) {
//       if (!mounted) return;
//       setState(() {
//         _errorMessage =
//             "Impossible de récupérer les informations de l'utilisateur.";
//       });
//       return;
//     }

//     final role = me['role']; // DONOR / ORG / ADMIN
//     final orgStatus = me['org_status']; // PENDING / APPROVED / REJECTED

//     if (!mounted) return;

//     if (role == 'ADMIN') {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const CampaignListPage()),
//       );
//       return;
//     }

//     if (role == 'ORG') {
//       if (orgStatus == 'APPROVED') {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const MyCampaignsPage()),
//         );
//       } else {
//         final msg = (orgStatus == 'REJECTED')
//             ? "Le compte de l'organisation a été refusé.\nVeuillez vérifier les informations et renvoyer."
//             : "Le compte de l'organisation est en cours de vérification.\nVous serez notifié après approbation.";

//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(orgStatus == 'REJECTED'
//                 ? 'Compte refusé'
//                 : 'En cours de vérification'),
//             content: Text(msg),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("D'accord"),
//               ),
//             ],
//           ),
//         );
//       }
//       return;
//     }

//     // DONOR/USER -> dashboard
//     Navigator.pushReplacementNamed(context, "/dashboard");
//   }

//   void _toggleMode() {
//     setState(() {
//       _isLoginMode = !_isLoginMode;
//       _errorMessage = null;
//       if (!_isLoginMode) _registerType = 'USER';
//     });
//   }

//   String _humanizeAuthError(String error) {
//     final e = error.toLowerCase();
//     if (e.contains('no active account') || e.contains('non activ')) {
//       return "Votre compte n'est pas encore activé. Vérifiez votre e-mail.";
//     }
//     if (e.contains('invalid') || e.contains('incorrect') || e.contains('wrong')) {
//       return "E-mail ou mot de passe incorrect.";
//     }
//     if (e.contains('already exists') || e.contains('unique')) {
//       return "Cet e-mail ou ce nom d'utilisateur est déjà utilisé.";
//     }
//     return error;
//   }

//   Future<void> _submit() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     final email = _emailController.text.trim();
//     final username = _usernameController.text.trim();
//     final firstName = _firstNameController.text.trim();
//     final lastName = _lastNameController.text.trim();
//     final orgName = _orgNameController.text.trim();
//     final orgPhone = _orgPhoneController.text.trim();
//     final orgAddress = _orgAddressController.text.trim();

//     final password = _passwordController.text.trim();
//     final confirmPassword = _confirmPasswordController.text.trim();

//     if (email.isEmpty || password.isEmpty || (!_isLoginMode && username.isEmpty)) {
//       setState(() {
//         _errorMessage = "Veuillez remplir tous les champs obligatoires.";
//         _isLoading = false;
//       });
//       return;
//     }

//     if (!_isLoginMode) {
//       if (password != confirmPassword) {
//         setState(() {
//           _errorMessage =
//               "Le mot de passe et la confirmation ne correspondent pas.";
//           _isLoading = false;
//         });
//         return;
//       }

//       if (_registerType == 'USER') {
//         if (firstName.isEmpty || lastName.isEmpty) {
//           setState(() {
//             _errorMessage = "Veuillez saisir le prénom et le nom.";
//             _isLoading = false;
//           });
//           return;
//         }
//       } else {
//         if (orgName.isEmpty) {
//           setState(() {
//             _errorMessage = "Le nom de l'organisation est obligatoire.";
//             _isLoading = false;
//           });
//           return;
//         }
//       }
//     }

//     try {
//       String? error;

//       if (_isLoginMode) {
//         error = await _authService.login(email: email, password: password);

//         if (!mounted) return;

//         if (error == null) {
//           await _redirectAfterLogin();
//         } else {
//           setState(() => _errorMessage = _humanizeAuthError(error!));
//         }
//       } else {
//         if (_registerType == 'USER') {
//           error = await _authService.register(
//             email: email,
//             username: username,
//             firstName: firstName,
//             lastName: lastName,
//             password: password,
//           );
//         } else {
//           error = await _orgService.registerOrg(
//             email: email,
//             username: username,
//             password: password,
//             name: orgName,
//             phone: orgPhone,
//             address: orgAddress,
//           );
//         }

//         if (!mounted) return;

//         if (error == null) {
//           setState(() {
//             // ✅ مهم: نص آمن بدون سطور حقيقية داخل " "
//             _errorMessage = (_registerType == 'USER')
//                 ? "Compte créé avec succès.\nVérifiez votre e-mail pour activer le compte."
//                 : "Organisation enregistrée avec succès.\nVérifiez votre e-mail d'abord.\nEnsuite, le compte restera en cours de vérification jusqu'à l'approbation de l'administrateur.";
//             _isLoginMode = true;
//           });
//         } else {
//           setState(() => _errorMessage = _humanizeAuthError(error!));
//         }
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _errorMessage = "Erreur inattendue : $e");
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _loginWithGoogle() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     final String? error = await _authService.loginWithGoogle();

//     if (!mounted) return;

//     if (error == null) {
//       await _redirectAfterLogin();
//     } else {
//       setState(() => _errorMessage = _humanizeAuthError(error));
//     }

//     if (mounted) setState(() => _isLoading = false);
//   }

//   Future<void> _loginWithFacebook() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     if (kIsWeb) {
//       web.callFacebookLoginJS();
//     } else {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "La connexion Facebook est activée uniquement sur le Web.";
//       });
//     }
//   }

//   Future<void> _handleFacebookTokenLogin(String token) async {
//     final String? error = await _authService.loginWithFacebookToken(token);

//     if (!mounted) return;

//     if (error == null) {
//       await _redirectAfterLogin();
//     } else {
//       setState(() => _errorMessage = _humanizeAuthError(error));
//     }

//     if (mounted) setState(() => _isLoading = false);
//   }

//   void _openForgotPassword() {
//     Navigator.pushNamed(context, "/forgot-password");
//   }

//   // =========================
//   // UI Helpers
//   // =========================
//   InputDecoration _dec({
//     required String label,
//     required IconData icon,
//     Widget? suffix,
//     String? hint,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: Icon(icon),
//       suffixIcon: suffix,
//       filled: true,
//       fillColor: Colors.white.withOpacity(0.92),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: BorderSide(color: Colors.purple.withOpacity(0.15)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: const BorderSide(color: Colors.purple, width: 1.6),
//       ),
//     );
//   }

//   Widget _gradientButton({
//     required String text,
//     required VoidCallback? onPressed,
//     bool loading = false,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       height: 50,
//       child: DecoratedBox(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           gradient: const LinearGradient(
//             begin: Alignment.centerRight,
//             end: Alignment.centerLeft,
//             colors: [Color(0xff7a1fa2), Color(0xffc04ee6)],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.purple.withOpacity(0.25),
//               blurRadius: 18,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: ElevatedButton(
//           onPressed: loading ? null : onPressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.transparent,
//             shadowColor: Colors.transparent,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//           ),
//           child: loading
//               ? const SizedBox(
//                   height: 22,
//                   width: 22,
//                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                 )
//               : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         ),
//       ),
//     );
//   }

//   Widget _socialButton({
//     required IconData icon,
//     required String text,
//     required VoidCallback? onTap,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       height: 44,
//       child: OutlinedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, size: 22),
//         label: Text(text),
//         style: OutlinedButton.styleFrom(
//           foregroundColor: Colors.purple,
//           backgroundColor: Colors.white.withOpacity(0.85),
//           side: BorderSide(color: Colors.purple.withOpacity(0.18)),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         ),
//       ),
//     );
//   }

//   Widget _errorBox(String msg) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xffffeef0),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xfff5b5bd)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.error_outline, color: Colors.red),
//           const SizedBox(width: 8),
//           Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, height: 1.3))),
//         ],
//       ),
//     );
//   }

//   Widget _header() {
//     return Column(
//       children: [
//         Container(
//           height: 72,
//           width: 72,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             gradient: const LinearGradient(colors: [Color(0xff7a1fa2), Color(0xffc04ee6)]),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.purple.withOpacity(0.25),
//                 blurRadius: 18,
//                 offset: const Offset(0, 10),
//               )
//             ],
//           ),
//           child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 38),
//         ),
//         const SizedBox(height: 14),
//         Text(
//           _isLoginMode ? 'Connexion' : 'Créer un compte',
//           style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _isLoginMode ? 'Bon retour' : 'Créez votre compte rapidement et commencez à donner',
//           style: TextStyle(color: Colors.black.withOpacity(0.55)),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _glassCard({required Widget child}) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(26),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//         child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.78),
//             borderRadius: BorderRadius.circular(26),
//             border: Border.all(color: Colors.white.withOpacity(0.55)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.10),
//                 blurRadius: 30,
//                 offset: const Offset(0, 18),
//               )
//             ],
//           ),
//           child: Padding(padding: const EdgeInsets.all(22), child: child),
//         ),
//       ),
//     );
//   }

//   Widget _bg() {
//     return Stack(
//       children: [
//         Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [Color(0xfffde9ff), Color(0xfff7f0ff)],
//             ),
//           ),
//         ),
//         Positioned(
//           top: -70,
//           right: -50,
//           child: Container(
//             height: 180,
//             width: 180,
//             decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withOpacity(0.10)),
//           ),
//         ),
//         Positioned(
//           bottom: -90,
//           left: -70,
//           child: Container(
//             height: 220,
//             width: 220,
//             decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withOpacity(0.08)),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isArabic = Localizations.localeOf(context).languageCode == "ar";
//     final titleBtn = _isLoginMode ? 'Se connecter' : "Créer le compte";

//     return Directionality(
//       textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
//       child: Scaffold(
//         body: Stack(
//           children: [
//             _bg(),
//             Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(18),
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 440),
//                   child: _glassCard(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         _header(),
//                         const SizedBox(height: 22),

//                         TextField(
//                           controller: _emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           decoration: _dec(
//                             label: 'E-mail',
//                             hint: 'Entrez votre e-mail',
//                             icon: Icons.email_outlined,
//                           ),
//                         ),
//                         const SizedBox(height: 12),

//                         if (!_isLoginMode) ...[
//                           DropdownButtonFormField<String>(
//                             value: _registerType,
//                             items: const [
//                               DropdownMenuItem(value: 'USER', child: Text('Utilisateur')),
//                               DropdownMenuItem(value: 'ORG', child: Text('Organisation')),
//                             ],
//                             onChanged: (v) => setState(() => _registerType = v ?? 'USER'),
//                             decoration: _dec(label: 'Type de compte', icon: Icons.account_circle_outlined),
//                           ),
//                           const SizedBox(height: 12),

//                           TextField(
//                             controller: _usernameController,
//                             decoration: _dec(
//                               label: "Nom d'utilisateur",
//                               hint: "Entrez votre nom d'utilisateur",
//                               icon: Icons.person_outline,
//                             ),
//                           ),
//                           const SizedBox(height: 12),

//                           if (_registerType == 'USER') ...[
//                             TextField(
//                               controller: _firstNameController,
//                               decoration: _dec(label: 'Prénom', hint: 'Entrez votre prénom', icon: Icons.badge_outlined),
//                             ),
//                             const SizedBox(height: 12),
//                             TextField(
//                               controller: _lastNameController,
//                               decoration: _dec(label: 'Nom', hint: 'Entrez votre nom', icon: Icons.family_restroom_outlined),
//                             ),
//                             const SizedBox(height: 12),
//                           ],

//                           if (_registerType == 'ORG') ...[
//                             TextField(
//                               controller: _orgNameController,
//                               decoration: _dec(label: "Nom de l'organisation", hint: "Entrez le nom de l'organisation", icon: Icons.business_outlined),
//                             ),
//                             const SizedBox(height: 12),
//                             TextField(
//                               controller: _orgPhoneController,
//                               decoration: _dec(label: "Téléphone (optionnel)", hint: "Entrez le téléphone", icon: Icons.phone_outlined),
//                             ),
//                             const SizedBox(height: 12),
//                             TextField(
//                               controller: _orgAddressController,
//                               decoration: _dec(label: "Adresse (optionnel)", hint: "Entrez l'adresse", icon: Icons.location_on_outlined),
//                             ),
//                             const SizedBox(height: 12),
//                           ],
//                         ],

//                         TextField(
//                           controller: _passwordController,
//                           obscureText: _obscurePassword,
//                           decoration: _dec(
//                             label: 'Mot de passe',
//                             hint: 'Entrez votre mot de passe',
//                             icon: Icons.lock_outline,
//                             suffix: IconButton(
//                               onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                               icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
//                             ),
//                           ),
//                         ),

//                         if (_isLoginMode) ...[
//                           const SizedBox(height: 6),
//                           Align(
//                             alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
//                             child: TextButton(
//                               onPressed: _isLoading ? null : _openForgotPassword,
//                               child: const Text("Mot de passe oublié ?", style: TextStyle(fontWeight: FontWeight.w700)),
//                             ),
//                           ),
//                         ],

//                         const SizedBox(height: 12),

//                         if (!_isLoginMode)
//                           TextField(
//                             controller: _confirmPasswordController,
//                             obscureText: _obscureConfirm,
//                             decoration: _dec(
//                               label: 'Confirmer le mot de passe',
//                               hint: 'Retapez le mot de passe',
//                               icon: Icons.lock_reset_outlined,
//                               suffix: IconButton(
//                                 onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
//                                 icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
//                               ),
//                             ),
//                           ),

//                         const SizedBox(height: 14),

//                         if (_errorMessage != null) ...[
//                           _errorBox(_errorMessage!),
//                           const SizedBox(height: 12),
//                         ],

//                         _gradientButton(
//                           text: titleBtn,
//                           onPressed: _isLoading ? null : _submit,
//                           loading: _isLoading,
//                         ),
//                         const SizedBox(height: 14),

//                         Row(
//                           children: [
//                             Expanded(child: Divider(color: Colors.black.withOpacity(0.10))),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 10),
//                               child: Text('ou', style: TextStyle(color: Colors.black.withOpacity(0.45))),
//                             ),
//                             Expanded(child: Divider(color: Colors.black.withOpacity(0.10))),
//                           ],
//                         ),

//                         const SizedBox(height: 12),

//                         _socialButton(
//                           icon: Icons.g_mobiledata,
//                           text: 'Se connecter avec Google',
//                           onTap: _isLoading ? null : _loginWithGoogle,
//                         ),
//                         const SizedBox(height: 10),
//                         _socialButton(
//                           icon: Icons.facebook,
//                           text: 'Se connecter avec Facebook',
//                           onTap: _isLoading ? null : _loginWithFacebook,
//                         ),

//                         const SizedBox(height: 10),

//                         TextButton(
//                           onPressed: _isLoading ? null : _toggleMode,
//                           child: Text(
//                             _isLoginMode
//                                 ? "Vous n’avez pas de compte ? Créer un compte"
//                                 : "Vous avez déjà un compte ? Se connecter",
//                             style: const TextStyle(fontWeight: FontWeight.w700),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
