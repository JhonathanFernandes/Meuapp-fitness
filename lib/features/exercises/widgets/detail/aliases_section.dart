/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 - 2026 wger Team
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

import 'package:material_ui/material_ui.dart';
import 'package:wger/features/exercises/models/translation.dart';

class AliasesSection extends StatelessWidget {
  final Translation translation;

  const AliasesSection({super.key, required this.translation});

  bool _looksLikeEnglish(String value) {
    return RegExp(
      r'\\b(with|and|for|from|the|to|your|alternate|added|stability|muscles|rectus|obliques|plank|bird dog|leg curl|hip thrust|incline|decline|standing|seated|lying|dumbbell|barbell|cable|machine|push up|pull down|deadlift|squat|crunch|row|press|raise|curl|extension)\\b',
      caseSensitive: false,
    ).hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final aliases = translation.aliases
        .map((item) => item.alias.trim())
        .where((alias) => alias.isNotEmpty && !_looksLikeEnglish(alias))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outros nomes',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          aliases.isEmpty
              ? 'Nenhum outro nome cadastrado.'
              : aliases.join(', '),
        ),
        const SizedBox(height: 9),
      ],
    );
  }
}
