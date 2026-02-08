import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _success;

  bool _showPass1 = false;
  bool _showPass2 = false;

  String? token;

  // ✅ Token extraction for Flutter Web hash route: /#/reset-password?token=...
  String? _extractTokenFromUrl() {
    final uri = Uri.base;

    // 1) normal query
    final direct = uri.queryParameters['token'];
    if (direct != null && direct.isNotEmpty) return direct;

    // 2) web hash fragment
    final frag = uri.fragment; // "/reset-password?token=UUID"
    if (frag.isEmpty) return null;

    final cleaned = frag.startsWith('/') ? frag.substring(1) : frag;
    final fragUri = Uri.parse(cleaned);
    final t = fragUri.queryParameters['token'];
    if (t != null && t.isNotEmpty) return t;

    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    token = _extractTokenFromUrl();

    if (token == null || token!.isEmpty) {
      setState(() {
        _error = "Lien invalide ou expiré.";
      });
    }
  }

  Future<void> _resetPassword() async {
    token ??= _extractTokenFromUrl();
    if (token == null || token!.isEmpty) {
      setState(() => _error = "Lien invalide ou expiré.");
      return;
    }

    final p1 = _passwordController.text.trim();
    final p2 = _confirmController.text.trim();

    if (p1.isEmpty || p2.isEmpty) {
      setState(() => _error = "Veuillez remplir les deux champs.");
      return;
    }

    if (p1 != p2) {
      setState(() => _error = "Les mots de passe ne correspondent pas.");
      return;
    }

    if (p1.length < 6) {
      setState(() => _error = "Mot de passe trop court (min 6 caractères).");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/auth/reset-password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": token,
          "new_password": p1,
          "confirm_password": p2,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          _success = data["detail"] ?? "Mot de passe modifié avec succès ✅";
        });

        // ⏱️ Redirect to login after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        });
      } else {
        setState(() {
          _error = data["detail"] ?? "Une erreur est survenue.";
        });
      }
    } catch (_) {
      setState(() {
        _error = "Impossible de se connecter au serveur.";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6F3FF),
              Color(0xFFF7F7FB),
              Color(0xFFF3EEFF),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.white.withOpacity(0.92),
                elevation: 12,
                shadowColor: Colors.black12,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header icon
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Icon(Icons.lock_reset, color: Colors.white, size: 34),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        "Réinitialiser le mot de passe",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Entrez votre nouveau mot de passe puis confirmez-le.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Password 1
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPass1,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: "Nouveau mot de passe",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _showPass1 ? "Masquer" : "Afficher",
                            onPressed: () => setState(() => _showPass1 = !_showPass1),
                            icon: Icon(_showPass1 ? Icons.visibility_off : Icons.visibility),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Password 2
                      TextField(
                        controller: _confirmController,
                        obscureText: !_showPass2,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _loading ? null : _resetPassword(),
                        decoration: InputDecoration(
                          labelText: "Confirmer le mot de passe",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _showPass2 ? "Masquer" : "Afficher",
                            onPressed: () => setState(() => _showPass2 = !_showPass2),
                            icon: Icon(_showPass2 ? Icons.visibility_off : Icons.visibility),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_error != null)
                        _MessageBanner(
                          text: _error!,
                          icon: Icons.error_outline,
                          background: const Color(0xFFFFEBEE),
                          foreground: const Color(0xFFD32F2F),
                          border: const Color(0xFFFFCDD2),
                        ),

                      if (_success != null)
                        _MessageBanner(
                          text: _success!,
                          icon: Icons.check_circle_outline,
                          background: const Color(0xFFE8F5E9),
                          foreground: const Color(0xFF2E7D32),
                          border: const Color(0xFFC8E6C9),
                        ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text("Confirmer"),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                ),
                        child: const Text("Retour à la connexion"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.text,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String text;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
