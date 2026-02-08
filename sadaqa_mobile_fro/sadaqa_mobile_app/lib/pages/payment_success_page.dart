import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key, required this.baseUrl});
  final String baseUrl;

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool _loading = true;
  String? _error;

  // On stocke uniquement les données affichées à l’utilisateur
  String _amount = "—";
  String? _donationId; // Optionnel (si tu ne veux pas l’afficher, retire-le de l’UI)

  Timer? _autoBackTimer;

  // ✅ Extraire session_id depuis le hash routing ou la query
  String? _getSessionId() {
    // hash: "#/payment-success?session_id=..."
    final fragment = Uri.base.fragment;
    final qIndex = fragment.indexOf('?');
    if (qIndex != -1) {
      final queryString = fragment.substring(qIndex + 1);
      final params = Uri.splitQueryString(queryString);
      final sid = params['session_id'];
      if (sid != null && sid.isNotEmpty) return sid;
    }

    // fallback: "?session_id=..."
    final sid2 = Uri.base.queryParameters['session_id'];
    if (sid2 != null && sid2.isNotEmpty) return sid2;

    return null;
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  void _goBackToCampaignsAndRefresh() {
    _autoBackTimer?.cancel();
    Navigator.of(context).pushReplacementNamed(
      "/campaigns",
      arguments: {"refresh": true},
    );
  }

  String _formatAmount(dynamic v) {
    if (v == null) return "—";
    final s = v.toString().trim();
    if (s.endsWith(".00")) return s.substring(0, s.length - 3);
    return s;
  }

  Future<void> _confirm() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
        _amount = "—";
        _donationId = null;
      });

      final sessionId = _getSessionId();
      if (sessionId == null || sessionId.isEmpty) {
        throw Exception("session_id est absent dans l’URL");
      }

      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception("Reconnectez-vous (token introuvable)");
      }

      final res = await http.post(
        Uri.parse("${widget.baseUrl}/api/payments/confirm-checkout-session/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"session_id": sessionId}),
      );

      final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;

      if (res.statusCode == 200 || res.statusCode == 201) {
        // ✅ Ne pas afficher les IDs Stripe — prendre uniquement amount et donation_id (optionnel)
        if (body is Map<String, dynamic>) {
          final amount = _formatAmount(body["amount"]);
          final donationId = body["donation_id"]?.toString();

          setState(() {
            _amount = amount;
            _donationId = donationId;
            _loading = false;
          });
        } else {
          setState(() {
            _loading = false;
          });
        }

        // ✅ Retour automatique après 3 secondes (optionnel)
        _autoBackTimer?.cancel();
        _autoBackTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) _goBackToCampaignsAndRefresh();
        });

        return;
      }

      throw Exception("Échec de la confirmation : ${res.statusCode} - ${res.body}");
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _confirm();
  }

  @override
  void dispose() {
    _autoBackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // ✅ Français
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Paiement réussi"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackToCampaignsAndRefresh,
          ),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xfffde9ff), Color(0xfff7f0ff)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _loading
                    ? _LoadingCard()
                    : (_error != null)
                        ? _ErrorCard(
                            error: _error!,
                            onRetry: _confirm,
                            onBack: _goBackToCampaignsAndRefresh,
                          )
                        : _SuccessCard(
                            amount: _amount,
                            donationId: _donationId,
                            onBack: _goBackToCampaignsAndRefresh,
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 6),
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              "Confirmation du paiement et enregistrement du don...",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  final String error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 10),
            const Text(
              "Un problème est survenu lors de la confirmation du paiement",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Réessayer"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Retour aux campagnes"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.amount,
    required this.donationId,
    required this.onBack,
  });

  final String amount;
  final String? donationId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 56, color: Colors.green),
            ),
            const SizedBox(height: 14),
            const Text(
              "Don enregistré avec succès ✅",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Montant : $amount \$",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Merci pour votre soutien 🤍",
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),

            // ✅ Optionnel : numéro interne (pas les IDs Stripe)
            if (donationId != null && donationId!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                "N° du don : $donationId",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.volunteer_activism),
                label: const Text("Retour aux campagnes"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Retour automatique dans quelques instants...",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
