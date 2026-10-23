/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2025 wger Team
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

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';
import 'package:wger/features/smart_training/meu_fit_plan_screen.dart';
import 'package:wger/features/routines/widgets/app_bar.dart';
import 'package:wger/features/routines/widgets/forms/routine.dart';
import 'package:wger/features/routines/widgets/routines_list.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class RoutineListScreen extends riverpod.ConsumerWidget {
  const RoutineListScreen();

  static const routeName = '/workout-plans-list';

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);

    return Scaffold(
      appBar: const RoutineListAppBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isOnline ? null : Colors.grey,
        onPressed: isOnline
            ? () {
                Navigator.pushNamed(
                  context,
                  FormScreen.routeName,
                  arguments: FormScreenArguments(
                    AppLocalizations.of(context).newRoutine,
                    RoutineForm(Routine.empty(), useListView: true),
                    hasListView: true,
                  ),
                );
              }
            : null,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    final profile = await MeuFitOnboardingStorage().load();
                    if (!context.mounted) return;
                    if (profile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(
                          'Complete o cadastro inicial para ver seu treino sugerido.',
                        )),
                      );
                      return;
                    }
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (routeContext) => MeuFitPlanScreen(
                          profile: profile,
                          onContinue: () => Navigator.of(routeContext).pop(),
                        ),
                      ),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(
                        'Não foi possível carregar seu treino sugerido.',
                      )),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC9F31D),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Meu treino sugerido'),
              ),
            ),
          ),
          const Expanded(child: WidescreenWrapper(child: RoutinesList())),
        ],
      ),
    );
  }
}
