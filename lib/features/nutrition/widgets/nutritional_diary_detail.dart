/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/models/nutritional_values.dart';
import 'package:wger/features/nutrition/widgets/charts.dart';
import 'package:wger/features/nutrition/widgets/nutrition_tiles.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class NutritionalDiaryDetailWidget extends StatefulWidget {
  final NutritionalPlan _nutritionalPlan;
  final DateTime _date;

  const NutritionalDiaryDetailWidget(this._nutritionalPlan, this._date);

  @override
  State<NutritionalDiaryDetailWidget> createState() => _NutritionalDiaryDetailWidgetState();
}

class _NutritionalDiaryDetailWidgetState extends State<NutritionalDiaryDetailWidget> {
  static const _tacoLogsKey = 'meu_fit_taco_food_logs_v1';
  late Future<List<Map<String, dynamic>>> _tacoEntriesFuture;

  @override
  void initState() {
    super.initState();
    _tacoEntriesFuture = _loadTacoEntriesForDate();
  }

  Future<List<Map<String, dynamic>>> _loadTacoEntriesForDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tacoLogsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map<String, dynamic>>().where((entry) {
        final date = DateTime.tryParse((entry['dateTime'] ?? '').toString());
        return date != null && date.year == widget._date.year &&
            date.month == widget._date.month && date.day == widget._date.day;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _deleteTacoEntry(Map<String, dynamic> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir alimento?'),
        content: Text('Deseja remover ${(entry['name'] ?? 'este alimento').toString()} do diário?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tacoLogsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final updated = decoded.whereType<Map<String, dynamic>>()
            .where((item) => item['id'] != entry['id']).toList();
        await prefs.setString(_tacoLogsKey, jsonEncode(updated));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o alimento.')),
        );
        return;
      }
    }
    if (mounted) setState(() => _tacoEntriesFuture = _loadTacoEntriesForDate());
  }

  @override
  Widget build(BuildContext context) {
    final nutritionalGoals = widget._nutritionalPlan.nutritionalGoals;
    final baseValues = widget._nutritionalPlan.getValuesForDate(widget._date);
    final logs = widget._nutritionalPlan.getLogsForDate(widget._date);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tacoEntriesFuture,
      builder: (context, snapshot) {
        final tacoEntries = snapshot.data ?? const <Map<String, dynamic>>[];
        if (baseValues == null && tacoEntries.isEmpty) return const Text('');

        final valuesLogged = NutritionalValues()..add(baseValues ?? NutritionalValues());
        double amount(Map<String, dynamic> entry, String key) {
          final v = entry[key];
          return v is num ? v.toDouble() : 0;
        }
        for (final entry in tacoEntries) {
          valuesLogged.add(NutritionalValues.values(
            amount(entry, 'energyKcal'), amount(entry, 'proteinG'),
            amount(entry, 'carbohydrateG'), 0, amount(entry, 'lipidsG'),
            0, amount(entry, 'fiberG'), 0,
          ));
        }

        return Column(children: [
          Card(child: Column(children: [
            Container(
              padding: const EdgeInsets.all(15),
              height: 220,
              child: FlNutritionalPlanPieChartWidget(valuesLogged),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: NutritionDiaryTable(
                planned: nutritionalGoals.toValues(), logged: valuesLogged,
              ),
            ),
          ])),
          if (tacoEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('ALIMENTOS TACO REGISTRADOS',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            ...tacoEntries.map((entry) {
              final grams = entry['grams'], energy = entry['energyKcal'];
              final protein = entry['proteinG'], carbs = entry['carbohydrateG'];
              final fat = entry['lipidsG'];
              return Card(child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text((entry['name'] ?? 'Alimento').toString()),
                subtitle: Text(
                  '${grams is num ? grams.toStringAsFixed(0) : '?'} g · '
                  '${energy is num ? energy.toStringAsFixed(0) : '—'} kcal\n'
                  'P ${protein is num ? protein.toStringAsFixed(1) : '—'} g · '
                  'C ${carbs is num ? carbs.toStringAsFixed(1) : '—'} g · '
                  'G ${fat is num ? fat.toStringAsFixed(1) : '—'} g',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Excluir do diário',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTacoEntry(entry),
                ),
              ));
            }),
          ],
          const SizedBox(height: 15),
          const DiaryheaderTile(),
          ...logs.map((e) => DiaryEntryTile(
            diaryEntry: e, nutritionalPlan: widget._nutritionalPlan)),
        ]);
      },
    );
  }
}

class NutritionDiaryTable extends StatelessWidget {
  const NutritionDiaryTable({
    super.key,
    required this.planned,
    required this.logged,
  });

  static const double tablePadding = 7;
  final NutritionalValues planned;
  final NutritionalValues logged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    Widget columnHeader(bool left, String title) => Padding(
      padding: const EdgeInsets.symmetric(vertical: tablePadding),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: left ? TextAlign.left : TextAlign.right,
      ),
    );

    TableRow macroRow(int indent, bool g, String title, double Function(NutritionalValues nv) get) {
      final valFn = g ? loc.gValue : loc.kcalValue;
      return TableRow(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: tablePadding, horizontal: indent * 12),
            child: Text(title),
          ),
          Text(valFn(get(planned).toStringAsFixed(0)), textAlign: TextAlign.right),
          Text(valFn(get(logged).toStringAsFixed(0)), textAlign: TextAlign.right),
          Text((get(logged) - get(planned)).toStringAsFixed(0), textAlign: TextAlign.right),
        ],
      );
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(width: 1, color: Theme.of(context).colorScheme.outline),
      ),
      columnWidths: const {0: FractionColumnWidth(0.4)},
      children: [
        TableRow(
          children: [
            columnHeader(true, loc.macronutrients),
            columnHeader(false, loc.planned),
            columnHeader(false, loc.logged),
            columnHeader(false, loc.difference),
          ],
        ),
        macroRow(0, false, loc.energy, (NutritionalValues nv) => nv.energy),
        macroRow(0, true, loc.protein, (NutritionalValues nv) => nv.protein),
        macroRow(0, true, loc.carbohydrates, (NutritionalValues nv) => nv.carbohydrates),
        macroRow(1, true, loc.sugars, (NutritionalValues nv) => nv.carbohydratesSugar),
        macroRow(0, true, loc.fat, (NutritionalValues nv) => nv.fat),
        macroRow(1, true, loc.saturatedFat, (NutritionalValues nv) => nv.fatSaturated),
        macroRow(0, true, loc.fiber, (NutritionalValues nv) => nv.fiber),
        macroRow(0, true, loc.sodium, (NutritionalValues nv) => nv.sodium),
      ],
    );
  }
}
