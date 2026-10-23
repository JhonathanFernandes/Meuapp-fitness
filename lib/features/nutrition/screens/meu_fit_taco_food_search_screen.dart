import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('Alimentos da TACO')),
      body: _loadingList
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('DADOS NUTRICIONAIS',
                    style: TextStyle(color: lime, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Pesquise alimentos da TACO (4ª edição, NEPA/UNICAMP). '
                  'Os dados são consultados online; é necessária conexão com a internet.',
                ),
                const SizedBox(height: 14),
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
                    onPressed: _selectedFood == null ? _loadFoods : () {
                      final food = _foods.where((f) => f['id'] == _selectedFood?['id']).firstOrNull;
                      if (food != null) _selectFood(food);
                    },
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
                const SizedBox(height: 12),
                Text('${results.length} resultados exibidos',
                    style: const TextStyle(color: Colors.white70)),
                ...results.map((food) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text((food['description'] ?? 'Alimento').toString()),
                  subtitle: Text((food['category'] ?? '').toString()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectFood(food),
                )),
                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhum alimento encontrado com esse nome.'),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Referência: TACO, 4ª edição (NEPA/UNICAMP). Os valores são por '
                  '100 g da parte comestível; a porção é calculada proporcionalmente. '
                  'Este recurso consulta dados e ainda não grava o alimento no diário.',
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
