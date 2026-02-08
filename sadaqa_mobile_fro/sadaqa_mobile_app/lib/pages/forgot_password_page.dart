import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.baseUrl});
  final String baseUrl;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _msg;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  InputDecoration _dec({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
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

  Widget _glass({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withOpacity(0.10),
            ),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -70,
          child: Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withOpacity(0.08),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final email = _email.text.trim();

    if (email.isEmpty) {
      setState(() {
        _err = "Veuillez saisir votre e-mail.";
        _msg = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
      _msg = null;
    });

    try {
      // ✅ غيّر endpoint حسب Django عندك
      final res = await http.post(
        Uri.parse("${widget.baseUrl}/api/auth/forgot-password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _msg =
              "✅ Si cet e-mail existe, un message de réinitialisation a été envoyé.\nVeuillez vérifier votre boîte de réception.";
        });
      } else {
        setState(() {
          _err = "❌ Erreur: ${res.statusCode}\n${res.body}";
        });
      }
    } catch (e) {
      setState(() => _err = "❌ Erreur réseau: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == "ar";

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
                  child: _glass(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xff7a1fa2), Color(0xffc04ee6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: const Icon(Icons.lock_reset, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Mot de passe oublié",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Entrez votre e-mail pour recevoir un lien de réinitialisation.",
                          style: TextStyle(color: Colors.black.withOpacity(0.55)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),

                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec(
                            label: "E-mail",
                            hint: "Entrez votre e-mail",
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (_err != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xffffeef0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xfff5b5bd)),
                            ),
                            child: Text(_err!, textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 10),
                        ],

                        if (_msg != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.purple.withOpacity(0.12)),
                            ),
                            child: Text(_msg!, textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 10),
                        ],

                        SizedBox(
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
                              onPressed: _loading ? null : _send,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text("Envoyer",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, "/login"),
                          child: const Text("← Retour à la connexion"),
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
