import 'package:flutter/material.dart';
import '../services/campaign_service.dart';
import '../services/organization_service.dart';
import '../config/api_config.dart';

class NewCampaignPage extends StatefulWidget {
  const NewCampaignPage({super.key});

  @override
  State<NewCampaignPage> createState() => _NewCampaignPageState();
}

class _NewCampaignPageState extends State<NewCampaignPage> {
  final String baseUrl = ApiConfig.baseUrl;

  final _campaignService = CampaignService();
  late final OrganizationService _orgService;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool _loadingOrg = true;
  bool _hasOrg = false;
  String? _orgName;

  @override
  void initState() {
    super.initState();
    _orgService = OrganizationService(baseUrl);
    _loadOrgInfo();
  }

  Future<void> _loadOrgInfo() async {
    try {
      final org = await _orgService.getMyOrg();
      setState(() {
        _hasOrg = org != null;
        _orgName = (org?["name"] ?? "").toString().trim();
        _loadingOrg = false;
      });
    } catch (_) {
      setState(() {
        _hasOrg = false;
        _orgName = null;
        _loadingOrg = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
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
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 1.6),
      ),
    );
  }

  Color get _primary => const Color(0xFF6D28D9);
  Color get _bg => const Color(0xFFF6F4FF);

  Widget _badge() {
    final isOrg = _hasOrg;

    final title = isOrg ? "Campagne d’organisation" : "Campagne publique";
    final subtitle = isOrg
        ? "Apparaîtra dans les campagnes des organisations après approbation"
        : "Apparaîtra dans les campagnes publiques après approbation";

    final name = (_orgName != null && _orgName!.isNotEmpty) ? _orgName! : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(.18)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isOrg ? Icons.apartment : Icons.public, color: _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                if (isOrg && name != null) ...[
                  const SizedBox(height: 2),
                  Text("Organisation : $name",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    final goalText = _goalController.text.trim();

    if (title.isEmpty || goalText.isEmpty) {
      setState(() {
        _errorMessage = "Le titre et le montant sont obligatoires.";
        _isLoading = false;
      });
      return;
    }

    final goal = double.tryParse(goalText.replaceAll(',', '.'));
    if (goal == null || goal <= 0) {
      setState(() {
        _errorMessage = "Veuillez saisir un montant valide.";
        _isLoading = false;
      });
      return;
    }

    try {
      final ok = await _campaignService.createCampaign(
        title: title,
        description: desc,
        goalAmount: goal.toString(),
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasOrg
                ? "Campagne d’organisation créée ✅"
                : "Campagne créée ✅"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() => _errorMessage =
            "Impossible d’enregistrer. Vérifiez votre connexion.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Erreur : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _formCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Détails de la campagne",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: _dec(label: "Titre de la campagne", icon: Icons.title_outlined),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _dec(
                label: "Description courte",
                icon: Icons.description_outlined,
                hint: "Pourquoi avez-vous besoin de dons ?",
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _goalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec(
                label: "Montant demandé",
                icon: Icons.attach_money,
                hint: "Exemple : 5000",
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            const SizedBox(height: 14),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Enregistrer",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == "ar";

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text("Nouvelle campagne"),
          centerTitle: true,
          backgroundColor: _bg,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: SafeArea(
          child: _loadingOrg
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, c) {
                    final maxW = c.maxWidth;
                    final width = maxW > 620 ? 620.0 : maxW;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      child: Center(
                        child: SizedBox(
                          width: width,
                          child: Column(
                            children: [
                              _badge(),
                              const SizedBox(height: 14),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 24,
                                      offset: const Offset(0, 14),
                                      color: Colors.black.withOpacity(.06),
                                    ),
                                  ],
                                ),
                                child: _formCard(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
