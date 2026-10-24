import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';

/// Pesquisa a TACO 4ª edição através da API estática pública.
/// Valores retornados pela fonte são expressos por 100 g de parte comestível.
class MeuFitTacoFoodSearchScreen extends StatefulWidget {
  const MeuFitTacoFoodSearchScreen({super.key});

  @override
  State<MeuFitTacoFoodSearchScreen> createState() =>
      _MeuFitTacoFoodSearchScreenState();
}

class _MeuFitTacoFoodSearchScreenState
    extends State<MeuFitTacoFoodSearchScreen> {
  static const _baseUrl = 'https://brolesi.github.io/taco';
  final _searchController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  List<Map<String, dynamic>> _foods = [];
  Map<String, dynamic>? _selectedFood;
  bool _loadingList = true;
  bool _loadingDetail = false;
  String? _error;
  List<Map<String, dynamic>> _loggedFoods = [];
  bool _saving = false;
  MeuFitOnboardingProfile? _profile;
  bool _introShown = false;
  static const _customTimesKey = 'meu_fit_custom_meal_times_v1';
  static const _customFoodsKey = 'meu_fit_custom_meal_foods_v1';
  Map<String, List<String>> _customMealTimes = {};
  Map<String, List<String>> _customMealFoods = {};
  Map<String, Map<String, dynamic>> _confirmedMealFoods = {};
  static const _confirmedMealFoodsKey = 'meu_fit_confirmed_meal_foods_v1';

  @override
  void initState() {
    super.initState();
    _loadLoggedFoods();
    _loadCustomMealTimes();
    _loadCustomMealFoods();
    _loadConfirmedMealFoods();
    _loadFoods();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileAndShowIntro());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    super.dispose();
  }


  static const _logsKey = 'meu_fit_taco_food_logs_v1';

  Future<void> _loadProfileAndShowIntro() async {
    final profile = await MeuFitOnboardingStorage().load();
    if (!mounted) return;
    setState(() => _profile = profile);
    if (_introShown) return;
    _introShown = true;
    final water = profile == null ? null : (profile.weightKg * 0.03).clamp(1.5, 4.0);
    final bmi = profile == null ? null : profile.weightKg / ((profile.heightCm / 100) * (profile.heightCm / 100));
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF202020),
      icon: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFC9F31D), size: 34),
      title: const Text('Seu guia de alimentação', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFC9F31D), fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(profile == null ? 'Veja um exemplo de cardápio simples e econômico. Complete seu peso e altura no perfil para personalizar as estimativas.' : 'Estas estimativas usam os dados informados no seu perfil. São orientações iniciais e não substituem avaliação nutricional.', style: const TextStyle(color: Colors.white70, height: 1.45)),
        const SizedBox(height: 14),
        if (water != null) _introMetric(Icons.water_drop_outlined, 'Água: cerca de ' + water.toStringAsFixed(1).replaceAll('.', ',') + ' L/dia', 'Estimativa inicial; clima, exercício e condições de saúde alteram a necessidade.'),
        const SizedBox(height: 10),
        _introMetric(Icons.schedule_rounded, 'Exemplo: 5 refeições ao dia', 'Café da manhã, lanche, almoço, lanche da tarde e jantar. Ajuste conforme sua fome e rotina.'),
        if (bmi != null) ...[const SizedBox(height: 10), _introMetric(Icons.monitor_weight_outlined, 'IMC calculado: ' + bmi.toStringAsFixed(1).replaceAll('.', ','), 'Indicador de triagem; não define sozinho a dieta ideal nem o estado de saúde.')],
        const SizedBox(height: 14),
        const Text('O cardápio prioriza arroz, feijão, ovos, frango, frutas e legumes, seguindo o Guia Alimentar para a População Brasileira.', style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 12)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Ver meu cardápio', style: TextStyle(color: Color(0xFFC9F31D), fontWeight: FontWeight.bold)))],
    ));
  }

  Widget _introMetric(IconData icon, String title, String detail) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: const Color(0xFFC9F31D), size: 22), const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(detail, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35))]))
  ]);

  static const List<Map<String, dynamic>> _weeklyMenu = [
    {'day':'Segunda-feira','meals':[['07:30','Café da manhã','Aveia 40 g, leite 200 ml e banana 1 unidade'],['10:30','Lanche','Mamão 150 g e amendoim 15 g'],['12:30','Almoço','Arroz cozido 100 g, feijão 100 g, frango 100 g e salada 100 g'],['16:00','Lanche da tarde','Pão 50 g e ovo cozido 1 unidade'],['19:30','Jantar','Arroz 80 g, feijão 80 g, omelete com 2 ovos e legumes 100 g']]},
    {'day':'Terça-feira','meals':[['07:30','Café da manhã','Pão 50 g, 2 ovos e mamão 100 g'],['10:30','Lanche','Banana 1 unidade e aveia 15 g'],['12:30','Almoço','Arroz 100 g, feijão 100 g, carne moída magra 100 g e cenoura 100 g'],['16:00','Lanche da tarde','Iogurte natural 170 g e aveia 20 g'],['19:30','Jantar','Batata cozida 180 g, frango 100 g e salada 100 g']]},
    {'day':'Quarta-feira','meals':[['07:30','Café da manhã','Cuscuz cozido 150 g e 2 ovos'],['10:30','Lanche','Laranja 1 unidade e amendoim 15 g'],['12:30','Almoço','Arroz 100 g, feijão 100 g, sardinha 100 g e couve 80 g'],['16:00','Lanche da tarde','Pão 50 g e queijo branco 30 g'],['19:30','Jantar','Sopa caseira de legumes 300 g com frango 80 g']]},
    {'day':'Quinta-feira','meals':[['07:30','Café da manhã','Aveia 40 g, leite 200 ml e maçã 1 unidade'],['10:30','Lanche','Banana 1 unidade e amendoim 15 g'],['12:30','Almoço','Arroz 100 g, feijão 100 g, frango 100 g e abóbora 100 g'],['16:00','Lanche da tarde','Iogurte natural 170 g e mamão 100 g'],['19:30','Jantar','Omelete com 2 ovos, batata 150 g e salada 100 g']]},
    {'day':'Sexta-feira','meals':[['07:30','Café da manhã','Pão 50 g, 2 ovos e banana 1 unidade'],['10:30','Lanche','Laranja 1 unidade e aveia 15 g'],['12:30','Almoço','Arroz 100 g, feijão 100 g, carne magra 100 g e salada 100 g'],['16:00','Lanche da tarde','Mandioca cozida 100 g e ovo cozido 1 unidade'],['19:30','Jantar','Arroz 80 g, feijão 80 g, sardinha 100 g e legumes 100 g']]},
    {'day':'Sábado','meals':[['08:00','Café da manhã','Pão integral 50 g, queijo branco 30 g e mamão 150 g'],['10:30','Lanche','Banana 1 unidade e iogurte natural 170 g'],['12:30','Almoço','Arroz 100 g, feijão 100 g, frango 100 g e legumes 100 g'],['16:00','Lanche da tarde','Aveia 30 g e leite 200 ml'],['19:30','Jantar','Batata-doce 150 g, ovos 2 unidades e salada 100 g']]},
    {'day':'Domingo','meals':[['08:00','Café da manhã','Cuscuz cozido 150 g e 2 ovos'],['10:30','Lanche','Maçã 1 unidade e amendoim 15 g'],['12:30','Almoço','Arroz 100 g, feijão 100 g, carne assada 100 g e salada 100 g'],['16:00','Lanche da tarde','Pão 50 g e queijo branco 30 g'],['19:30','Jantar','Sopa de legumes 300 g com frango 80 g']]}
  ];

  Future<void> _loadCustomMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customTimesKey);
    if (raw == null || !mounted) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() => _customMealTimes = decoded.map(
        (day, times) => MapEntry(day, (times as List<dynamic>).map((v) => v.toString()).toList()),
      ));
    } catch (_) {
      // Um registro antigo inválido não deve bloquear o cardápio.
    }
  }

  Future<void> _loadCustomMealFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customFoodsKey);
    if (raw == null || !mounted) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() => _customMealFoods = decoded.map(
        (key, value) => MapEntry(key, (value as List<dynamic>).map((v) => v.toString()).toList()),
      ));
    } catch (_) {
      // Ignora apenas os alimentos personalizados inválidos.
    }
  }

  Future<void> _loadConfirmedMealFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_confirmedMealFoodsKey);
    if (raw == null || !mounted) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() => _confirmedMealFoods = decoded.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
      ));
    } catch (_) {
      // Um registro inválido não deve bloquear o cardápio.
    }
  }

  Future<void> _addMealTime(String day) async {
    final controller = TextEditingController();
    TimeOfDay? selectedTime;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF202020),
          title: const Text('Adicionar horário'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Escolha um horário para criar outra refeição neste dia.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              label: Text(selectedTime == null ? 'Selecionar horário' : selectedTime!.format(context)),
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) setDialogState(() => selectedTime = picked);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome da refeição', hintText: 'Ex.: Ceia'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: selectedTime == null ? null : () {
                final label = controller.text.trim().isEmpty ? 'Nova refeição' : controller.text.trim();
                Navigator.pop(dialogContext, '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}|$label');
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final updated = Map<String, List<String>>.from(_customMealTimes);
    updated[day] = [...(updated[day] ?? []), result]..sort();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customTimesKey, jsonEncode(updated));
    if (mounted) setState(() => _customMealTimes = updated);
  }

  String _foodSearchKey(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áàâãéêíóôõúç ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  List<String> _mealForCurrentProfile(List<String> meal) {
    final profile = _profile;
    if (profile == null) return meal;
    var description = meal[2];
    // Ajusta as opções demonstrativas por objetivo, sem inventar meta calórica.
    if (profile.goal == 'emagrecer') {
      description = description
          .replaceAll('Pão 50 g', 'Pão integral 50 g')
          .replaceAll('Arroz cozido 100 g', 'Arroz cozido 80 g')
          .replaceAll('Arroz 100 g', 'Arroz 80 g')
          .replaceAll('Arroz 80 g', 'Arroz 80 g')
          .replaceAll('Amendoim 15 g', 'Fruta 130 g');
    } else if (profile.goal == 'ganhar_massa') {
      description = description
          .replaceAll('Arroz cozido 100 g', 'Arroz cozido 130 g')
          .replaceAll('Arroz 100 g', 'Arroz 130 g')
          .replaceAll('Arroz 80 g', 'Arroz 120 g')
          .replaceAll('frango 100 g', 'frango 130 g')
          .replaceAll('Frango 100 g', 'Frango 130 g')
          .replaceAll('carne moída magra 100 g', 'carne moída magra 130 g')
          .replaceAll('sardinha 100 g', 'sardinha 130 g')
          .replaceAll('2 ovos', '3 ovos');
    }
    return [meal[0], meal[1], description];
  }

  Future<void> _openMealDetails(String day, List<String> meal) async {
    final effectiveMeal = _mealForCurrentProfile(meal);
    final description = effectiveMeal[2];
    final parts = description
        .split(RegExp(r',|\s+e\s+', caseSensitive: false))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: Text(effectiveMeal[1], style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('$day · ${effectiveMeal[0]}', style: const TextStyle(color: Color(0xFFC9F31D), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Alimentos deste horário', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final part in parts)
                _buildMealFoodRow(part, dialogContext),
              const SizedBox(height: 12),
              const Text(
                'A tabela apresenta valores por 100 g quando o alimento é encontrado na base TACO. Para itens sem correspondência exata, pesquise o nome no catálogo abaixo e confira o preparo antes de usar os valores.',
                style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _searchController.text = '';
                  FocusScope.of(context).unfocus();
                },
                icon: const Icon(Icons.search),
                label: const Text('Pesquisar qualquer alimento da TACO'),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fechar'))],
      ),
    );
  }

  Future<void> _openCustomMealDetails(String day, String entry) async {
    final parts = entry.split('|');
    final time = parts.first;
    final name = parts.length > 1 ? parts[1] : 'Nova refeição';
    final foodController = TextEditingController();
    final mealKey = '$day|$entry';
    final foods = List<String>.from(_customMealFoods[mealKey] ?? const <String>[]);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF202020),
          title: Text(name),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$day · $time', style: const TextStyle(color: Color(0xFFC9F31D))),
              const SizedBox(height: 12),
              TextField(controller: foodController, decoration: const InputDecoration(labelText: 'Adicionar alimento', hintText: 'Ex.: pão, iogurte, banana')),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  final value = foodController.text.trim();
                  if (value.isEmpty) return;
                  setDialogState(() { foods.add(value); foodController.clear(); });
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar alimento à refeição'),
              ),
              const SizedBox(height: 8),
              if (foods.isEmpty) const Text('Adicione alimentos a este horário. Depois, toque em cada alimento para pesquisar a tabela nutricional.', style: TextStyle(color: Colors.white70)),
              for (final food in foods) _buildMealFoodRow(food, dialogContext),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fechar'))],
        ),
      ),
    );
    foodController.dispose();
    final updatedFoods = Map<String, List<String>>.from(_customMealFoods);
    updatedFoods[mealKey] = foods;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customFoodsKey, jsonEncode(updatedFoods));
    if (mounted) setState(() => _customMealFoods = updatedFoods);
  }

  Widget _buildMealFoodRow(String itemText, BuildContext dialogContext) {
    final confirmed = _confirmedMealFoods[itemText];
    final food = confirmed == null ? null : _foods.cast<Map<String, dynamic>?>().firstWhere(
      (entry) => entry?['id'] == confirmed['foodId'],
      orElse: () => null,
    );
    final grams = confirmed?['grams'] is num ? (confirmed!['grams'] as num).toDouble() : null;
    String n(dynamic value) => value is num && grams != null
        ? (value * grams / 100).toStringAsFixed(1).replaceAll('.', ',')
        : '—';
    return Card(
      color: const Color(0xFF292929),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(itemText, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          food != null && grams != null
              ? 'TACO confirmado: ${food['description']} · ${grams.toStringAsFixed(grams == grams.roundToDouble() ? 0 : 1).replaceAll('.', ',')} g\n${n(food['energy_kcal'])} kcal · proteína ${n(food['protein_g'])} g · carboidratos ${n(food['carbohydrate_g'])} g · gorduras ${n(food['lipids_g'])} g · fibras ${n(food['dietary_fiber_g'])} g · sódio ${n(food['sodium_mg'])} mg'
              : 'Ainda sem correspondência confirmada. Escolha o alimento exato na TACO e informe a quantidade em gramas; não será presumido o peso de unidades.',
          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Selecionar alimento exato na TACO',
          icon: Icon(food != null && grams != null ? Icons.edit : Icons.search, color: const Color(0xFFC9F31D)),
          onPressed: () => _chooseTacoFoodForMeal(itemText, dialogContext),
        ),
      ),
    );
  }

  Future<void> _chooseTacoFoodForMeal(String itemText, BuildContext parentDialogContext) async {
    final searchController = TextEditingController(
      text: itemText.replaceAll(RegExp(r'\d+(?:[.,]\d+)?\s*(?:g|ml|unidade|unidades|ovo|ovos)?', caseSensitive: false), ' ').trim(),
    );
    final gramsController = TextEditingController(
      text: RegExp(r'(\d+(?:[.,]\d+)?)\s*g\b', caseSensitive: false)
              .firstMatch(itemText)?.group(1) ?? '100',
    );
    Map<String, dynamic>? selected;
    await showDialog<void>(
      context: parentDialogContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final query = _foodSearchKey(searchController.text);
          final results = _foods.where((food) {
            final name = _foodSearchKey((food['description'] ?? '').toString());
            final category = _foodSearchKey((food['category'] ?? '').toString());
            return query.isEmpty || name.contains(query) || category.contains(query);
          }).take(30).toList();
          final grams = double.tryParse(gramsController.text.trim().replaceAll(',', '.'));
          String n(dynamic value) => value is num && grams != null && grams > 0
              ? (value * grams / 100).toStringAsFixed(1).replaceAll('.', ',')
              : '—';
          return AlertDialog(
            backgroundColor: const Color(0xFF202020),
            title: const Text('Confirmar alimento e porção'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: searchController,
                  onChanged: (_) => setDialogState(() => selected = null),
                  decoration: const InputDecoration(labelText: 'Pesquisar na base TACO', prefixIcon: Icon(Icons.search)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: gramsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(labelText: 'Quantidade em gramas', suffixText: 'g'),
                ),
                const SizedBox(height: 8),
                if (selected == null)
                  SizedBox(
                    height: 220,
                    child: results.isEmpty
                        ? const Center(child: Text('Nenhum resultado. Tente outro nome.'))
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (_, index) {
                              final food = results[index];
                              return ListTile(
                                dense: true,
                                title: Text((food['description'] ?? 'Alimento').toString()),
                                subtitle: Text((food['category'] ?? '').toString()),
                                onTap: () => setDialogState(() => selected = food),
                              );
                            },
                          ),
                  )
                else ...[
                  Text((selected!['description'] ?? 'Alimento').toString(),
                    style: const TextStyle(color: Color(0xFFC9F31D), fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('${n(selected!['energy_kcal'])} kcal  ·  Proteína ${n(selected!['protein_g'])} g\nCarboidratos ${n(selected!['carbohydrate_g'])} g  ·  Gorduras ${n(selected!['lipids_g'])} g\nFibras ${n(selected!['dietary_fiber_g'])} g  ·  Sódio ${n(selected!['sodium_mg'])} mg',
                    style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => setDialogState(() => selected = null), child: const Text('Escolher outro alimento')),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              FilledButton(
                onPressed: selected == null || grams == null || grams <= 0
                    ? null
                    : () {
                        final picked = selected!;
                        final confirmed = Map<String, Map<String, dynamic>>.from(_confirmedMealFoods);
                        confirmed[itemText] = {
                          'foodId': picked['id'],
                          'name': (picked['description'] ?? 'Alimento').toString(),
                          'grams': grams,
                        };
                        SharedPreferences.getInstance().then((prefs) async {
                          await prefs.setString(_confirmedMealFoodsKey, jsonEncode(confirmed));
                          if (mounted) setState(() => _confirmedMealFoods = confirmed);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Valores da TACO salvos para ${grams.toStringAsFixed(1).replaceAll('.', ',')} g de ${picked['description']}.')),
                        );
                      },
                child: const Text('Confirmar valores'),
              ),
            ],
          );
        },
      ),
    );
    searchController.dispose();
    gramsController.dispose();
  }

  Widget _profileNutritionGuidance() {
    final profile = _profile;
    if (profile == null) {
      return const Card(
        color: Color(0xFF202020),
        child: ListTile(
          leading: Icon(Icons.person_outline, color: Color(0xFFC9F31D)),
          title: Text('Personalize o cardápio pelo seu perfil'),
          subtitle: Text('Preencha idade, peso, altura e objetivo no perfil para adaptar as opções alimentares.'),
        ),
      );
    }
    final bmi = profile.weightKg / ((profile.heightCm / 100) * (profile.heightCm / 100));
    final goal = switch (profile.goal) {
      'emagrecer' => 'Redução de peso',
      'ganhar_massa' => 'Hipertrofia / ganho de massa',
      'manter_forma' => 'Manutenção',
      'flexibilidade' => 'Condicionamento e mobilidade',
      _ => 'Objetivo não definido',
    };
    final strategy = switch (profile.goal) {
      'emagrecer' => 'Priorize refeições com vegetais, frutas, leguminosas e proteínas menos gordurosas; ajuste porções e energia total com acompanhamento profissional.',
      'ganhar_massa' => 'Distribua fontes de proteína ao longo do dia e combine-as com carboidratos para sustentar o treino e a recuperação. A quantidade depende do perfil completo e do treino.',
      'manter_forma' => 'Mantenha variedade entre alimentos in natura, leguminosas, cereais, frutas e fontes de proteína, com porções coerentes com sua rotina.',
      'flexibilidade' => 'Use uma alimentação variada e suficiente para sustentar atividade e recuperação; a meta não é automaticamente emagrecer nem ganhar massa.',
      _ => 'Use variedade alimentar e ajuste as porções às necessidades individuais.',
    };
    final bmiText = profile.age < 20
        ? 'IMC calculado: ${bmi.toStringAsFixed(1).replaceAll('.', ',')} (para menores de 20 anos, a interpretação exige curva por idade e sexo).'
        : 'IMC calculado: ${bmi.toStringAsFixed(1).replaceAll('.', ',')} (indicador de triagem; não define sozinho a dieta nem a composição corporal).';
    return Card(
      color: const Color(0xFF202020),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ESTRATÉGIA ALIMENTAR DO SEU PERFIL',
            style: TextStyle(color: Color(0xFFC9F31D), fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(goal, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${profile.age} anos · ${profile.weightKg.toStringAsFixed(1).replaceAll('.', ',')} kg · ${profile.heightCm.toStringAsFixed(0)} cm',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(bmiText, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(strategy, style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 12)),
          const SizedBox(height: 8),
          const Text('A estratégia muda conforme objetivo e dados do perfil; o IMC sozinho não define calorias, macros nem uma dieta clínica.',
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.35)),
        ]),
      ),
    );
  }

  Widget _weeklyMenuSection() {
    const lime = Color(0xFFC9F31D);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('SEU CARDÁPIO DA SEMANA', style: TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
      const SizedBox(height: 5), const Text('Toque em um dia para abrir as refeições', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      ..._weeklyMenu.map((day) {
        final dayName = day['day'] as String;
        final meals = day['meals'] as List<List<String>>;
        final extraTimes = _customMealTimes[dayName] ?? const <String>[];
        return Card(
          color: const Color(0xFF202020),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ExpansionTile(
            leading: const Icon(Icons.calendar_today_rounded, color: lime),
            title: Text(dayName, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${meals.length + extraTimes.length} refeições · toque em um horário para ver os alimentos',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
            children: [
              for (final meal in meals)
                InkWell(
                  onTap: () => _openMealDetails(dayName, meal),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 48, child: Text(meal[0], style: const TextStyle(color: lime, fontWeight: FontWeight.w800, fontSize: 12))),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(meal[1], style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(_mealForCurrentProfile(meal)[2], style: const TextStyle(color: Colors.white70, height: 1.35, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('Ver alimentos e tabela nutricional ›', style: TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.w700)),
                      ])),
                    ]),
                  ),
                ),
              for (final entry in extraTimes)
                ListTile(
                  leading: const Icon(Icons.schedule_rounded, color: lime),
                  title: Text(entry.split('|').length > 1 ? entry.split('|')[1] : 'Nova refeição'),
                  subtitle: Text('${entry.split('|').first} · horário personalizado'),
                  onTap: () => _openCustomMealDetails(dayName, entry),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: OutlinedButton.icon(
                  onPressed: () => _addMealTime(dayName),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar outro horário'),
                ),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 6),
      const Text('Porções ilustrativas, não uma prescrição individual. Calorias e proporções de nutrientes dependem de idade, atividade, objetivo, preferências e condições de saúde. Para metas precisas, procure nutricionista.', style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4)),
      const SizedBox(height: 8),
      const Text('Referência: Ministério da Saúde — Guia Alimentar para a População Brasileira.', style: TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 3),
      const SelectableText('https://www.gov.br/saude/pt-br/assuntos/saude-brasil/publicacoes-para-promocao-a-saude/guia_alimentar_populacao_brasileira_2ed.pdf', style: TextStyle(color: lime, fontSize: 10)),
      const SizedBox(height: 18),
    ]);
  }

  Future<void> _loadLoggedFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_logsKey);
    if (raw == null || !mounted) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      setState(() => _loggedFoods = decoded.whereType<Map<String, dynamic>>().toList());
    } catch (_) {
      // Registros inválidos não devem impedir a pesquisa de alimentos.
    }
  }

  Future<void> _saveFoodToDiary() async {
    final food = _selectedFood;
    final grams = _grams;
    if (food == null || grams <= 0 || !grams.isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma porção válida, maior que zero.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final entry = <String, dynamic>{
        'id': '${now.microsecondsSinceEpoch}',
        'foodId': food['id'],
        'name': (food['description'] ?? 'Alimento').toString(),
        'category': (food['category'] ?? '').toString(),
        'grams': grams,
        'dateTime': now.toIso8601String(),
        'energyKcal': _scaled(food['energy_kcal'], grams),
        'proteinG': _scaled(food['protein_g'], grams),
        'carbohydrateG': _scaled(food['carbohydrate_g'], grams),
        'lipidsG': _scaled(food['lipids_g'], grams),
        'fiberG': _scaled(food['dietary_fiber_g'], grams),
        'source': 'TACO / NEPA-UNICAMP',
      };
      final prefs = await SharedPreferences.getInstance();
      final updated = [entry, ..._loggedFoods];
      await prefs.setString(_logsKey, jsonEncode(updated));
      if (!mounted) return;
      setState(() {
        _loggedFoods = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consumo registrado neste aparelho.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível registrar o consumo.')),
      );
    }
  }

  double? _scaled(dynamic value, double grams) =>
      value is num ? value * grams / 100 : null;

  Future<void> _deleteLoggedFood(Map<String, dynamic> entry) async {
    final updated = _loggedFoods.where((item) => item['id'] != entry['id']).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logsKey, jsonEncode(updated));
    if (mounted) setState(() => _loggedFoods = updated);
  }

  String _loggedNumber(dynamic value, String unit) {
    if (value is! num) return '—';
    return '${value.toStringAsFixed(1).replaceAll('.', ',')} $unit';
  }

  Future<void> _loadFoods() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/foods.json'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('Servidor respondeu ${response.statusCode}');
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = (json['foods'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
      if (!mounted) return;
      setState(() {
        _foods = items;
        _loadingList = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _error = 'Não foi possível carregar a TACO. Confira sua conexão e tente novamente.';
      });
    }
  }

  Future<void> _selectFood(Map<String, dynamic> food) async {
    final id = food['id'];
    if (id is! num) return;
    setState(() {
      _loadingDetail = true;
      _selectedFood = null;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('$_baseUrl/foods/${id.toInt()}.json'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('Servidor respondeu ${response.statusCode}');
      }
      final detail = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _selectedFood = detail;
        _loadingDetail = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _error = 'Não foi possível abrir os nutrientes desse alimento.';
      });
    }
  }

  double get _grams {
    final normalized = _gramsController.text.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 100;
  }

  String _number(dynamic value, {int decimals = 1}) {
    if (value is! num) return 'Não informado';
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  String _portion(dynamic value) {
    if (value is! num) return 'Não informado';
    return _number(value * _grams / 100);
  }

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    final query = _searchController.text.trim().toLowerCase();
    final results = query.isEmpty ? <Map<String, dynamic>>[] : _foods.where((food) {
      final description = (food['description'] ?? '').toString().toLowerCase();
      final category = (food['category'] ?? '').toString().toLowerCase();
      return query.isEmpty || description.contains(query) || category.contains(query);
    }).take(20).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dieta', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF101010),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Atualizar alimentos',
            onPressed: _loadingList ? null : _loadFoods,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loadingList
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF303A13), Color(0xFF20251A), Color(0xFF1B1B1B)],
                    ),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: lime.withValues(alpha: 0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(8)),
                          child: const Text('MEU FIT · ALIMENTAÇÃO',
                            style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                        ),
                        const Spacer(),
                        const Icon(Icons.restaurant_menu_rounded, color: lime, size: 25),
                      ]),
                      const SizedBox(height: 17),
                      const Text('Sua alimentação,\nsem complicação.',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.08, letterSpacing: -0.6)),
                      const SizedBox(height: 8),
                      const Text('Pesquise alimentos, veja os nutrientes por porção e registre o que comeu sem sair do aplicativo.',
                        style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 13)),
                      const SizedBox(height: 16),
                      Row(children: [
                        const Icon(Icons.bolt_rounded, color: lime, size: 18),
                        const SizedBox(width: 7),
                        Expanded(child: Text('${_foods.length} alimentos na base TACO',
                          style: const TextStyle(color: lime, fontWeight: FontWeight.w800, fontSize: 12))),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _profileNutritionGuidance(),
                const SizedBox(height: 10),
                _weeklyMenuSection(),
                const Text('ENCONTRE SEU ALIMENTO',
                  style: TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 5),
                const Text('Pesquisa dentro do app',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Buscar alimento',
                    hintText: 'Ex.: arroz, feijão, banana',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Limpar',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  TextButton.icon(
                    onPressed: _loadFoods,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
                if (_selectedFood != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFF242424),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_selectedFood!['description'] ?? 'Alimento').toString(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedFood!['category'] ?? ''} · TACO / NEPA-UNICAMP',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _gramsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Porção em gramas',
                              suffixText: 'g',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_number(_selectedFood!['energy_kcal'])} kcal por 100 g',
                            style: const TextStyle(color: lime, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _nutrientRow('Energia', _portion(_selectedFood!['energy_kcal']), 'kcal'),
                          _nutrientRow('Proteínas', _portion(_selectedFood!['protein_g']), 'g'),
                          _nutrientRow('Carboidratos', _portion(_selectedFood!['carbohydrate_g']), 'g'),
                          _nutrientRow('Lipídeos', _portion(_selectedFood!['lipids_g']), 'g'),
                          _nutrientRow('Fibras', _portion(_selectedFood!['dietary_fiber_g']), 'g'),
                          _nutrientRow('Sódio', _portion(_selectedFood!['sodium_mg']), 'mg'),
                          _nutrientRow('Cálcio', _portion(_selectedFood!['calcium_mg']), 'mg'),
                          _nutrientRow('Ferro', _portion(_selectedFood!['iron_mg']), 'mg'),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _saveFoodToDiary,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_task),
                              label: Text(_saving ? 'Registrando...' : 'Registrar consumo'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Fonte: Tabela Brasileira de Composição de Alimentos (TACO), '
                            '4ª edição, NEPA/UNICAMP. API estática de terceiros; confira '
                            'a descrição e o preparo do alimento. Campo ausente significa '
                            'dado não disponível, não valor zero.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => setState(() => _selectedFood = null),
                              child: const Text('Fechar detalhes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_loadingDetail)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_loggedFoods.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'CONSUMOS REGISTRADOS NESTE APARELHO',
                    style: TextStyle(color: lime, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._loggedFoods.map((entry) {
                    final date = DateTime.tryParse((entry['dateTime'] ?? '').toString());
                    final dateLabel = date == null
                        ? ''
                        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    return Card(
                      child: ListTile(
                        title: Text((entry['name'] ?? 'Alimento').toString()),
                        subtitle: Text(
                          '${_loggedNumber(entry['grams'], 'g')} · $dateLabel\n'
                          '${_loggedNumber(entry['energyKcal'], 'kcal')} · '
                          'P ${_loggedNumber(entry['proteinG'], 'g')} · '
                          'C ${_loggedNumber(entry['carbohydrateG'], 'g')} · '
                          'G ${_loggedNumber(entry['lipidsG'], 'g')}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Excluir registro',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteLoggedFood(entry),
                        ),
                      ),
                    );
                  }),
                  const Text(
                    'Esses registros ficam salvos localmente neste aparelho e ainda não são somados ao diário sincronizado do plano nutricional.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                if (query.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Digite o nome de um alimento para ver resultados. A lista fica oculta até você pesquisar.',
                      style: TextStyle(color: Colors.white60, height: 1.4)),
                  ),
                if (query.isNotEmpty) ...[
                Row(children: [
                  const Expanded(child: Text('ALIMENTOS DA TACO',
                    style: TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
                  Text('${results.length} resultados',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
                const SizedBox(height: 8),
                ...results.map((food) {
                  final kcal = food['energy_kcal'];
                  final protein = food['protein_g'];
                  final selected = _selectedFood?['id'] == food['id'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF292F1D) : const Color(0xFF202020),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: selected ? lime.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => _selectFood(food),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(color: const Color(0xFF30351F), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.restaurant_rounded, color: lime, size: 20),
                            ),
                            const SizedBox(width: 11),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text((food['description'] ?? 'Alimento').toString(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text((food['category'] ?? 'Alimento').toString(),
                                style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              if (kcal is num || protein is num) ...[
                                const SizedBox(height: 5),
                                Text('${kcal is num ? kcal.toStringAsFixed(0) : '—'} kcal · Proteína ${protein is num ? protein.toStringAsFixed(1) : '—'} g / 100 g',
                                  style: const TextStyle(color: lime, fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ])),
                            const Icon(Icons.add_circle_outline_rounded, color: lime, size: 22),
                          ]),
                        ),
                      ),
                    ),
                  );
                }),
                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhum alimento encontrado com esse nome.'),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Referência: TACO, 4ª edição (NEPA/UNICAMP). Os valores são por '
                  '100 g da parte comestível; a porção é calculada proporcionalmente. '
                  'Os registros ficam salvos localmente neste aparelho.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
    );
  }

  Widget _nutrientRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value == 'Não informado' ? value : '$value $unit'),
        ],
      ),
    );
  }
}
