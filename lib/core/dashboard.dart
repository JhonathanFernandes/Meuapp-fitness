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
import 'package:wger/core/app_settings_notifier.dart';
import 'package:wger/core/material.dart';
import 'package:wger/core/widgets/app_bar.dart';
import 'package:wger/core/widgets/dashboard/calendar.dart';
import 'package:wger/core/widgets/dashboard/widgets/measurements.dart';
import 'package:wger/core/widgets/dashboard/widgets/nutrition.dart';
import 'package:wger/core/widgets/dashboard/widgets/routines.dart';
import 'package:wger/core/widgets/dashboard/widgets/trophies.dart';
import 'package:wger/core/widgets/dashboard/widgets/weight.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final Future<MeuFitOnboardingProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = MeuFitOnboardingStorage().load();
  }

  Widget _getDashboardWidget(DashboardWidget widget) {
    switch (widget) {
      case DashboardWidget.routines:
        return const DashboardRoutineWidget();
      case DashboardWidget.weight:
        return const DashboardWeightWidget();
      case DashboardWidget.measurements:
        return const DashboardMeasurementWidget();
      case DashboardWidget.calendar:
        return const DashboardCalendarWidget();
      case DashboardWidget.nutrition:
        return const DashboardNutritionWidget();
      case DashboardWidget.trophies:
        return const DashboardTrophiesWidget();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < MATERIAL_XS_BREAKPOINT;
    final visibleWidgets = ref.watch(
      appSettingsProvider.select(
        (s) => (s.value?.dashboardItems ?? defaultDashboardItems).visibleWidgets,
      ),
    );

    late final int crossAxisCount;
    if (width < MATERIAL_XS_BREAKPOINT) {
      crossAxisCount = 1;
    } else if (width < MATERIAL_MD_BREAKPOINT) {
      crossAxisCount = 2;
    } else if (width < MATERIAL_LG_BREAKPOINT) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return Scaffold(
      appBar: MainAppBar(AppLocalizations.of(context).labelDashboard),
      body: Column(
        children: [
          FutureBuilder<MeuFitOnboardingProfile?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final String headline;
              if (snapshot.hasError) {
                headline = 'Não foi possível carregar seu perfil';
              } else if (snapshot.connectionState != ConnectionState.done) {
                headline = 'Carregando seu perfil...';
              } else if (profile == null) {
                headline = 'Acompanhe sua evolução';
              } else {
                headline = 'Objetivo: ${switch (profile.goal) {
                  'emagrecer' => 'Emagrecimento',
                  'ganhar_massa' => 'Ganhar massa muscular',
                  'manter_forma' => 'Manter a forma',
                  'flexibilidade' => 'Flexibilidade e mobilidade',
                  _ => 'Objetivo não identificado',
                }}';
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC9F31D).withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MEU FIT · SEU PAINEL',
                      style: TextStyle(
                        color: Color(0xFFC9F31D),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (snapshot.hasError) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Tente abrir o painel novamente. Seus dados não foram alterados.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ] else if (snapshot.connectionState != ConnectionState.done) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        color: Color(0xFFC9F31D),
                        minHeight: 3,
                      ),
                    ] else if (profile == null) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Complete seu perfil para personalizar seu acompanhamento.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Meta: ${profile.daysPerWeek} dias de treino por semana',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Peso inicial: ${profile.weightKg.toStringAsFixed(1)} kg',
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Expanded(child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: MATERIAL_LG_BREAKPOINT),
          child: isMobile
              ? ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) => _getDashboardWidget(visibleWidgets[index]),
                  itemCount: visibleWidgets.length,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) => SingleChildScrollView(
                    child: _getDashboardWidget(visibleWidgets[index]),
                  ),
                  itemCount: visibleWidgets.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.7,
                  ),
                ),
        ),
          ),
        ],
      ),
    );
  }
}
