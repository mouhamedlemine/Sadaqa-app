import 'package:flutter/material.dart';
import '../services/campaign_service.dart';

class EditCampaignPage extends StatefulWidget {
  final Map<String, dynamic> campaign;
  const EditCampaignPage({super.key, required this.campaign});

  @override
  State<EditCampaignPage> createState() => _EditCampaignPageState();
}

class _EditCampaignPageState extends State<EditCampaignPage> {
  final CampaignService _service = CampaignService();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _goal;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: (widget.campaign["title"] ?? "").toString());
    _description =
        TextEditingController(text: (widget.campaign["description"] ?? "").toString());
    _goal = TextEditingController(text: (widget.campaign["goal_amount"] ?? "").toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _goal.dispose();
    super.dispose();
  }

  InputDecoration _dec({
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final ok = await _service.updateCampaign(
        id: widget.campaign["id"],
        title: _title.text.trim(),
        description: _description.text.trim(),
        goalAmount: _goal.text.trim(),
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Campagne modifiée ✅")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de la modification")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr, // ✅ Français
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          centerTitle: true,
          title: const Text("Modifier la campagne"),
        ),
        body: LayoutBuilder(
          builder: (context, c) {
            final maxW = c.maxWidth;
            final contentW = maxW >= 900 ? 720.0 : (maxW >= 600 ? 560.0 : maxW);

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ===== Header Card =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              cs.primary.withOpacity(0.16),
                              cs.primary.withOpacity(0.06)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          border: Border.all(color: cs.primary.withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.edit_note_rounded,
                                  color: cs.primary, size: 26),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Mettez à jour les détails de votre campagne facilement",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Modifiez le titre, la description et l’objectif, puis appuyez sur Enregistrer.",
                                    style: TextStyle(
                                        fontSize: 12.8, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ===== Form Card =====
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Informations de la campagne",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 12),

                                TextFormField(
                                  controller: _title,
                                  textInputAction: TextInputAction.next,
                                  decoration: _dec(
                                    label: "Titre de la campagne",
                                    hint: "Exemple : Soutenir l’éducation",
                                    icon: Icons.title_rounded,
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? "Le titre est obligatoire"
                                      : null,
                                ),

                                const SizedBox(height: 12),

                                TextFormField(
                                  controller: _description,
                                  minLines: 3,
                                  maxLines: 6,
                                  decoration: _dec(
                                    label: "Description de la campagne",
                                    hint: "Écrivez une description claire et attractive…",
                                    icon: Icons.description_rounded,
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? "La description est obligatoire"
                                      : null,
                                ),

                                const SizedBox(height: 12),

                                TextFormField(
                                  controller: _goal,
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  decoration: _dec(
                                    label: "Montant demandé",
                                    hint: "Exemple : 1200",
                                    icon: Icons.attach_money_rounded,
                                    suffixText: "USD",
                                  ),
                                  validator: (v) {
                                    final val = double.tryParse((v ?? "").trim());
                                    if (val == null || val <= 0) {
                                      return "Entrez un montant valide";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _loading ? null : _save,
                                    icon: _loading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.check_circle_outline_rounded),
                                    label: Text(_loading
                                        ? "Enregistrement..."
                                        : "Enregistrer les modifications"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Remarque : la modification peut nécessiter une validation selon la politique de l’application.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
