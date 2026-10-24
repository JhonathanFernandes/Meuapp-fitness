/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2020 - 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/widgets/async_value_widget.dart';
import 'package:wger/features/account/providers/user_profile_notifier.dart';
import 'package:wger/features/measurements/charts/range.dart';
import 'package:wger/features/measurements/models/measurement_category.dart';
import 'package:wger/features/measurements/models/unit_conversion.dart';
import 'package:wger/features/measurements/providers/body_weight_provider.dart';
import 'package:wger/features/measurements/providers/chart_range_setting.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/features/measurements/screens/weight_screen.dart';
import 'package:wger/features/measurements/widgets/chart_range_selector.dart';
import 'package:wger/features/measurements/widgets/measurement_tile.dart';
import 'package:wger/features/measurements/widgets/weight_form.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

import 'categories_card.dart';

/// Body measurements worth tracking for a practical monthly progress view.
/// Values are entered in centimetres and the existing measurement history
/// keeps each entry so the user can compare months.
const _bodyMeasurementNames = <String>[
  'Abdômen',
  'Cintura',
  'Peito',
  'Ombros',
  'Braços',
  'Quadril',
  'Coxas',
  'Panturrilhas',
];

class CategoriesList extends ConsumerStatefulWidget {
  const CategoriesList();

  @override
  ConsumerState<CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends ConsumerState<CategoriesList> {
  bool _seedScheduled = false;

  void _ensureBodyMeasurementCategories(List<MeasurementCategory> categories) {
    if (_seedScheduled) return;
    _seedScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final existingNames = categories
          .where((category) => category.metricType == MetricType.custom)
          .map((category) => category.name.trim().toLowerCase())
          .toSet();

      for (final name in _bodyMeasurementNames) {
        if (existingNames.contains(name.toLowerCase())) continue;
        await ref.read(measurementProvider.notifier).addCategory(
          MeasurementCategory(name: name, unit: 'cm'),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // One range for the whole screen, shared with the detail screens through
    // the provider. The monthly range remains available for comparing progress.
    final range = ref.watch(chartRangeSettingProvider);

    return AsyncValueWidget<List<MeasurementCategory>>(
      value: ref.watch(measurementCategoriesProvider),
      loggerName: 'CategoriesList',
      data: (categoriesList) {
        _ensureBodyMeasurementCategories(categoriesList);

        // Keep body weight and the selected body measurements in this screen.
        // Imported health readings and unrelated cards remain stored, but are
        // not presented as fitness progress measurements.
        final topLevel = categoriesList.where((category) {
          if (category.parentId != null || category.isOfficialBodyWeight) {
            return false;
          }
          if (category.metricType != MetricType.custom) return false;
          return _bodyMeasurementNames.any(
            (name) => name.toLowerCase() == category.name.trim().toLowerCase(),
          );
        }).toList()
          ..sort((a, b) => _bodyMeasurementNames
              .indexOf(a.name)
              .compareTo(_bodyMeasurementNames.indexOf(b.name)));

        final weightCard = _weightCard(context, ref, range);

        return Column(
          children: [
            const SizedBox(height: 10),
            ChartRangeSelector(
              value: range,
              onChanged: (range) => ref.read(chartRangeSettingProvider.notifier).set(range),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (weightCard != null)
                    SliverPadding(
                      padding: const EdgeInsets.all(10),
                      sliver: SliverToBoxAdapter(child: weightCard),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: measurementTileExtent,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => MeasurementTile(topLevel[index], range: range),
                        childCount: topLevel.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// The body weight card, null while what it needs is still syncing.
  Widget? _weightCard(BuildContext context, WidgetRef ref, ChartRange range) {
    final category = ref.watch(bodyWeightCategoryOnlyProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    if (category == null || profile == null) {
      return null;
    }

    return CategoriesCard(
      category,
      range: range,
      title: AppLocalizations.of(context).weight,
      displayUnit: weightDisplayUnit(profile.isMetric),
      displayUnitLabel: weightUnit(profile.isMetric, context),
      newEntryForm: WeightForm(category),
      onShowDetails: () => Navigator.pushNamed(context, WeightScreen.routeName),
    );
  }
}
