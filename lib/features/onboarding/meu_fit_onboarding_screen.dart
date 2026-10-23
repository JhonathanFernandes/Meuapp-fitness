import 'package:flutter/material.dart';
import 'meu_fit_onboarding_profile.dart';

/// Fluxo inicial Meu Fit. Ainda precisa ser ligado à rota de entrada do app.
class MeuFitOnboardingScreen extends StatefulWidget {
  const MeuFitOnboardingScreen({super.key, this.onCompleted});
  final ValueChanged<MeuFitOnboardingProfile>? onCompleted;

  @override
  State<MeuFitOnboardingScreen> createState() => _MeuFitOnboardingScreenState();
}

class _MeuFitOnboardingScreenState extends State<MeuFitOnboardingScreen> {
  static const _lime = Color(0xFFC9F31D);
  static const _background = Color(0xFF101010);
  static const _surface = Color(0xFF242424);
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _limitations = TextEditingController();
  int _step = 0;
  int _days = 3;
  String _goal = 'emagrecer';
  String _experience = 'iniciante';
  String _location = 'academia';
  bool _hasLimitations = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _limitations.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, String suffix) => InputDecoration(
    labelText: label,
    suffixText: suffix,
    filled: true,
    fillColor: _surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );

  Widget _number(TextEditingController controller, String label, String suffix) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration(label, suffix),
          validator: (value) {
            final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
            if (parsed == null || !parsed.isFinite || parsed <= 0) {
              return 'Informe um número válido';
            }
            return null;
          },
        ),
      );

  Widget _choice(String title, String current, Map<String, String> options,
      ValueChanged<String> onChange) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...options.entries.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RadioListTile<String>(
              title: Text(option.value),
              value: option.key,
              groupValue: current,
              onChanged: (value) { if (value != null) setState(() => onChange(value)); },
              tileColor: _surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              activeColor: _lime,
            ),
          )),
        ],
      );

  Widget _page() => switch (_step) {
    0 => Column(children: [
      _number(_age, 'Qual é a sua idade?', 'anos'),
      _number(_weight, 'Qual é o seu peso?', 'kg'),
      _number(_height, 'Qual é a sua altura?', 'cm'),
    ]),
    1 => _choice('Qual é seu objetivo?', _goal, {
      'emagrecer': 'Emagrecer',
      'ganhar_massa': 'Ganhar massa muscular',
      'manter_forma': 'Manter a forma',
      'flexibilidade': 'Melhorar flexibilidade e mobilidade',
    }, (v) => _goal = v),
    2 => _choice('Qual é sua experiência?', _experience, {
      'iniciante': 'Iniciante',
      'intermediario': 'Intermediário',
      'avancado': 'Avançado',
    }, (v) => _experience = v),
    3 => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quantos dias por semana você quer treinar?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (var n = 1; n <= 7; n++)
          ChoiceChip(label: Text('$n'), selected: _days == n,
              onSelected: (_) => setState(() => _days = n)),
      ]),
    ]),
    4 => _choice('Onde você pretende treinar?', _location, {
      'academia': 'Na academia',
      'casa': 'Em casa',
    }, (v) => _location = v),
    _ => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Você possui alguma limitação física?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      SwitchListTile(
        title: const Text('Sim, tenho limitações'),
        value: _hasLimitations,
        activeColor: _lime,
        onChanged: (v) => setState(() => _hasLimitations = v),
      ),
      if (_hasLimitations)
        TextField(controller: _limitations, maxLines: 3,
          decoration: _decoration('Conte quais movimentos deve evitar', '')),
    ]),
  };

  Future<void> _next() async {
    if (_step == 0 && !_formKey.currentState!.validate()) return;
    if (_step < 5) {
      setState(() { _step++; _error = null; });
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final profile = MeuFitOnboardingProfile(
        age: int.parse(_age.text.trim()),
        weightKg: double.parse(_weight.text.trim().replaceAll(',', '.')),
        heightCm: double.parse(_height.text.trim().replaceAll(',', '.')),
        goal: _goal,
        experience: _experience,
        daysPerWeek: _days,
        trainingLocation: _location,
        hasPhysicalLimitations: _hasLimitations,
        limitationsDescription: _hasLimitations ? _limitations.text.trim() : '',
      );
      await MeuFitOnboardingStorage().save(profile);
      if (!mounted) return;
      widget.onCompleted?.call(profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suas informações foram salvas!')),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar. Confira os dados e tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: _background,
      colorScheme: const ColorScheme.dark(primary: _lime, surface: _surface),
    ),
    child: Scaffold(
      appBar: AppBar(title: const Text('Meu Fit'), backgroundColor: _background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              LinearProgressIndicator(value: (_step + 1) / 6,
                color: _lime, backgroundColor: _surface),
              const SizedBox(height: 24),
              Text('SEU PERFIL · ETAPA ${_step + 1} DE 6',
                style: const TextStyle(color: _lime, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Vamos montar seu treino',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 28),
              Expanded(child: SingleChildScrollView(child: _page())),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
              Row(children: [
                if (_step > 0)
                  TextButton(onPressed: _saving ? null : () => setState(() => _step--),
                    child: const Text('Voltar')),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _next,
                  style: FilledButton.styleFrom(backgroundColor: _lime,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
                  child: Text(_saving ? 'Salvando...' : _step == 5 ? 'Concluir' : 'Continuar'),
                ),
              ]),
            ]),
          ),
        ),
      ),
    ),
  );
}
