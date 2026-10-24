import 'package:flutter/material.dart';
import 'meu_fit_onboarding_profile.dart';

/// Calculadora de IMC integrada ao primeiro acesso do Meu Fit.
/// A classificação adulta é informativa e não substitui avaliação clínica.
class MeuFitBmiScreen extends StatefulWidget {
  const MeuFitBmiScreen({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  final MeuFitOnboardingProfile profile;
  final VoidCallback onContinue;

  @override
  State<MeuFitBmiScreen> createState() => _MeuFitBmiScreenState();
}

class _MeuFitBmiScreenState extends State<MeuFitBmiScreen> {
  static const _lime = Color(0xFFC9F31D);
  static const _background = Color(0xFF101010);
  static const _surface = Color(0xFF242424);
  late final TextEditingController _weight;
  late final TextEditingController _height;
  double? _bmi;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(text: widget.profile.weightKg.toStringAsFixed(1));
    _height = TextEditingController(text: widget.profile.heightCm.toStringAsFixed(0));
    _calculate();
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  void _calculate() {
    final weight = _number(_weight.text);
    final heightCm = _number(_height.text);
    if (weight == null || heightCm == null ||
        !weight.isFinite || !heightCm.isFinite ||
        weight < 20 || weight > 500 || heightCm < 100 || heightCm > 250) {
      setState(() {
        _bmi = null;
        _error = 'Informe um peso entre 20 e 500 kg e uma altura entre 100 e 250 cm.';
      });
      return;
    }
    final heightM = heightCm / 100;
    setState(() {
      _bmi = weight / (heightM * heightM);
      _error = null;
    });
  }

  String _classification(double bmi) {
    if (bmi < 18.5) return 'Abaixo do peso';
    if (bmi < 25) return 'Peso adequado (eutrofia)';
    if (bmi < 30) return 'Sobrepeso';
    if (bmi < 35) return 'Obesidade grau I';
    if (bmi < 40) return 'Obesidade grau II';
    return 'Obesidade grau III';
  }

  String _risk(double bmi) {
    if (bmi < 18.5) return 'O IMC baixo pode estar associado a risco nutricional; vale investigar a causa.';
    if (bmi < 25) return 'A faixa de IMC está associada a menor risco relacionado ao peso, mas não avalia todos os aspectos da saúde.';
    if (bmi < 30) return 'O risco de problemas relacionados ao peso pode estar aumentado.';
    if (bmi < 35) return 'O risco de condições associadas ao excesso de peso é elevado.';
    if (bmi < 40) return 'O risco de condições associadas ao excesso de peso é muito elevado.';
    return 'A classificação está associada a risco muito elevado de complicações e merece avaliação profissional prioritária.';
  }

  List<String> _possibleConcerns(double bmi) {
    if (bmi < 18.5) {
      return ['Possíveis deficiências nutricionais', 'Perda de massa muscular ou fraqueza, dependendo da causa'];
    }
    if (bmi < 25) {
      return ['O IMC isolado não identifica sintomas nem confirma que todos os indicadores de saúde estejam normais'];
    }
    if (bmi < 30) {
      return ['Maior risco futuro de pressão alta e diabetes tipo 2, conforme outros fatores individuais'];
    }
    return [
      'Diabetes tipo 2 e pressão arterial elevada',
      'Doenças cardiovasculares e alterações de colesterol',
      'Apneia do sono, ronco e sonolência diurna',
      'Sobrecarga das articulações e dores, especialmente nos joelhos',
      'Doença hepática gordurosa e outras complicações metabólicas',
    ];
  }

  Widget _section(String title, List<String> items, {String? description}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(color: Colors.white70, height: 1.4)),
            ],
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle, size: 6, color: _lime),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: const TextStyle(color: Colors.white70, height: 1.35))),
                  ],
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bmi = _bmi;
    final isAdult = widget.profile.age >= 18;
    final category = bmi == null ? null : _classification(bmi);
    final isHigh = bmi != null && bmi >= 30;

    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.dark(primary: _lime, surface: _surface),
        appBarTheme: const AppBarTheme(backgroundColor: _background, foregroundColor: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sua avaliação de IMC'),
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _lime.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MEU FIT · SAÚDE E BEM-ESTAR',
                        style: TextStyle(color: _lime, fontWeight: FontWeight.bold, letterSpacing: 0.7)),
                    const SizedBox(height: 10),
                    const Text('Conheça seu índice de massa corporal',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Usamos os dados do seu cadastro. Se precisar, ajuste as medidas e calcule novamente.',
                        style: TextStyle(color: Colors.white70, height: 1.4)),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: TextField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg', filled: true),
                        onSubmitted: (_) => _calculate(),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(
                        controller: _height,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Altura', suffixText: 'cm', filled: true),
                        onSubmitted: (_) => _calculate(),
                      )),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Calcular meu IMC'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _lime,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ],
                ),
              ),
              if (bmi != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isHigh ? const Color(0xFF35231F) : _surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: isHigh ? Colors.orangeAccent.withValues(alpha: 0.7) : _lime.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SEU RESULTADO', style: TextStyle(color: _lime, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
                      Text('IMC · kg/m²', style: const TextStyle(color: Colors.white60)),
                      const SizedBox(height: 12),
                      Text(
                        isAdult ? category! : 'IMC calculado — classificação por idade',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAdult ? _risk(bmi) : 'Como você tem menos de 18 anos, a classificação correta depende de curvas de crescimento por idade e sexo. Este resultado não deve ser interpretado pela tabela adulta.',
                        style: const TextStyle(color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
                if (isAdult) ...[
                  _section(
                    'O que essa classificação significa',
                    const [],
                    description: bmi >= 40
                        ? 'O IMC está na faixa de obesidade grau III. Isso não significa que todas as complicações estejam presentes, mas indica a importância de uma avaliação individual com um profissional de saúde.'
                        : bmi >= 30
                            ? 'O resultado está na faixa de obesidade. O IMC é uma ferramenta de triagem; a avaliação clínica considera também cintura, histórico, exames e outros fatores.'
                            : bmi >= 25
                                ? 'O resultado está na faixa de sobrepeso. A avaliação completa deve considerar medidas, histórico clínico e outros fatores individuais.'
                                : bmi < 18.5
                                    ? 'O resultado está abaixo da faixa adulta de referência. É importante entender o contexto, a alimentação e possíveis causas com um profissional.'
                                    : 'O resultado está na faixa adulta de referência. O IMC, sozinho, não confirma a saúde geral nem avalia a composição corporal.',
                  ),
                  _section(
                    bmi >= 25 ? 'Possíveis riscos à saúde' : 'Pontos importantes para acompanhar',
                    _possibleConcerns(bmi),
                    description: 'Esses são riscos possíveis, não diagnósticos. A presença e a intensidade variam de pessoa para pessoa.',
                  ),
                  if (bmi >= 30)
                    _section(
                      'Sinais que podem aparecer',
                      const [
                        'Falta de ar ao esforço ou cansaço em atividades do dia a dia',
                        'Ronco intenso ou sonolência durante o dia',
                        'Dores nos joelhos, quadris ou costas',
                        'Limitação de mobilidade em algumas atividades',
                      ],
                      description: 'Muitas pessoas não apresentam sintomas específicos. Esses sinais não confirmam obesidade e podem ter outras causas.',
                    ),
                ] else
                  _section(
                    'Por que a interpretação é diferente?',
                    const ['Em adolescentes, o IMC é comparado com curvas específicas para idade e sexo.', 'Procure um profissional de saúde para interpretar o resultado corretamente.'],
                  ),
                _section(
                  'Próximo passo recomendado',
                  const [
                    'Converse com um profissional de saúde ou com a equipe da UBS para avaliar o resultado no contexto da sua saúde.',
                    'Evite dietas extremas ou aumentar a intensidade dos exercícios de forma brusca.',
                    'A classificação do IMC não substitui consulta, exame físico ou exames laboratoriais.',
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    'Referência: Ministério da Saúde — Linhas de Cuidado da Obesidade no Adulto. O IMC não distingue gordura de massa muscular e deve ser interpretado com outros dados clínicos.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: widget.onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: const Text('Continuar para meu plano', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
