import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLoggedFoods();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    super.dispose();
  }


  static const _logsKey = 'meu_fit_taco_food_logs_v1';

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
    final results = _foods.where((food) {
      final description = (food['description'] ?? '').toString().toLowerCase();
      final category = (food['category'] ?? '').toString().toLowerCase();
      return query.isEmpty || description.contains(query) || category.contains(query);
    }).take(100).toList();

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
