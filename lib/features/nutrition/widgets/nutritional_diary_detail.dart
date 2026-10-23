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

class NutritionalDiaryDetailWidget extends StatelessWidget {
  final NutritionalPlan _nutritionalPlan;
  final DateTime _date;

  const NutritionalDiaryDetailWidget(this._nutritionalPlan, this._date);

  static const _tacoLogsKey = 'meu_fit_taco_food_logs_v1';

  Future<List<Map<String, dynamic>>> _loadTacoEntriesForDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tacoLogsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map<String, dynamic>>().where((entry) {
        final date = DateTime.tryParse((entry['dateTime'] ?? '').toString());
        return date != null && date.year == _date.year &&
            date.month == _date.month && date.day == _date.day;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutritionalGoals = _nutritionalPlan.nutritionalGoals;
    final baseValues = _nutritionalPlan.getValuesForDate(_date);
    final logs = _nutritionalPlan.getLogsForDate(_date);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadTacoEntriesForDate(),
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
              ));
            }),
          ],
          const SizedBox(height: 15),
          const DiaryheaderTile(),
          ...logs.map((e) => DiaryEntryTile(
            diaryEntry: e, nutritionalPlan: _nutritionalPlan)),
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
