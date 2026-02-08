import 'package:flutter/material.dart';
import '../services/volunteer_service.dart';

class VolunteerPage extends StatefulWidget {
  const VolunteerPage({super.key});

  @override
  State<VolunteerPage> createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> {
  final _service = VolunteerService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _skills = TextEditingController();
  final _notes = TextEditingController();

  // ✅ Compatible avec les choices Django
  String _volunteerType = "field"; // field | online
  String _timeSlot = "evening"; // morning | evening

  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _skills.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final payload = <String, dynamic>{
      "full_name": _name.text.trim(),
      "phone": _phone.text.trim(),
      "city": _city.text.trim(),
      "volunteer_type": _volunteerType, // ✅
      "time_slot": _timeSlot, // ✅
      "skills": _skills.text.trim(),
      "notes": _notes.text.trim(),
    };

    try {
      await _service.submitRequest(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Demande de bénévolat envoyée avec succès")),
      );

      _name.clear();
      _phone.clear();
      _city.clear();
      _skills.clear();
      _notes.clear();

      setState(() {
        _volunteerType = "field";
        _timeSlot = "evening";
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec de l’envoi : $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl, // ✅ gardé comme ton code (pas de changement UI)
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text("Bénévolat", style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  // ================= HEADER CARD =================
                  _HeaderCard(primary: cs.primary),

                  const SizedBox(height: 14),

                  // ================= MINI INFO =================
                  Row(
                    children: const [
                      Expanded(
                        child: _MiniInfo(icon: Icons.schedule, title: "Flexibilité", desc: "Choisis le temps"),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _MiniInfo(icon: Icons.groups_2, title: "Équipe", desc: "Travail en groupe"),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _MiniInfo(icon: Icons.handshake, title: "Impact", desc: "Aide concrète"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ================= FORM CARD =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.black12.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Informations du bénévole",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          _niceField(
                            controller: _name,
                            label: "Nom complet",
                            icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? "Saisis un nom valide"
                                : null,
                          ),
                          const SizedBox(height: 10),

                          _niceField(
                            controller: _phone,
                            label: "Numéro de téléphone",
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().length < 7)
                                ? "Saisis un numéro valide"
                                : null,
                          ),
                          const SizedBox(height: 10),

                          _niceField(
                            controller: _city,
                            label: "Ville",
                            icon: Icons.location_on_outlined,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? "Saisis la ville" : null,
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _niceDropdown(
                                  label: "Type de bénévolat",
                                  icon: Icons.work_outline,
                                  value: _volunteerType,
                                  items: const [
                                    DropdownMenuItem(value: "field", child: Text("Sur le terrain")),
                                    DropdownMenuItem(value: "online", child: Text("En ligne")),
                                  ],
                                  onChanged: (v) => setState(() => _volunteerType = v ?? "field"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _niceDropdown(
                                  label: "Temps disponible",
                                  icon: Icons.schedule,
                                  value: _timeSlot,
                                  items: const [
                                    DropdownMenuItem(value: "morning", child: Text("Matin")),
                                    DropdownMenuItem(value: "evening", child: Text("Soir")),
                                  ],
                                  onChanged: (v) => setState(() => _timeSlot = v ?? "evening"),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          _niceField(
                            controller: _skills,
                            label: "Compétences (optionnel)",
                            icon: Icons.star_border,
                            hint: "Ex: organisation, design, communication...",
                          ),
                          const SizedBox(height: 10),

                          _niceField(
                            controller: _notes,
                            label: "Remarques (optionnel)",
                            icon: Icons.notes_outlined,
                            maxLines: 3,
                            hint: "Toute information utile pour choisir un rôle adapté",
                          ),

                          const SizedBox(height: 14),

                          // ================= SUBMIT BUTTON =================
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [
                                      cs.primary.withOpacity(0.95),
                                      Colors.purple.withOpacity(0.85),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_submitting)
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      else
                                        const Icon(Icons.send, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        _submitting ? "Envoi en cours..." : "Envoyer la demande",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ================= PRIVACY =================
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_outline, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Nous ne partagerons pas vos données avec des tiers. Elles seront utilisées uniquement pour vous contacter concernant le bénévolat.",
                                    style: TextStyle(color: Colors.black54, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  // =================== WIDGETS HELPERS ===================
  Widget _niceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF7F9FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black12.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _niceDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF7F9FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black12.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.2),
        ),
      ),
    );
  }
}

// =================== UI COMPONENTS ===================
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            primary.withOpacity(0.95),
            Colors.purple.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fais partie du bien",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  "Remplis le formulaire et nous te contacterons pour rejoindre l’équipe de bénévolat.",
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.title, required this.desc});
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
