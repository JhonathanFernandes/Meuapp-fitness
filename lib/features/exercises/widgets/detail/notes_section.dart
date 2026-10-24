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
import 'package:wger/l10n/generated/app_localizations.dart';

class NotesSection extends StatelessWidget {
  final Translation translation;

  const NotesSection({super.key, required this.translation});

  bool _looksLikeEnglish(String value) {
    return RegExp(
      r'\\b(with|and|for|from|the|to|your|this|that|are|is|keep|maintain|hold|slow|slowly|start|return|alternate|added|top|stability|muscles|rectus|obliques|plank|bird dog|leg curl|hip thrust|incline|decline|standing|seated|lying|dumbbell|barbell|cable|machine|push up|pull down|deadlift|squat|crunch|row|press|raise|curl|extension|perform|exercise|movement|position|feet|hands|repeat|breathe|breath|weight|lower|lift|squeeze|engage|target|muscle|should|finish|spine|neutral|knees|elbows|shoulders|hips|straight|equipment|load|range|motion|throughout|avoid|without|until|between|each|side|arms|legs|chest|using|place)\\b',
      caseSensitive: false,
    ).hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final notes = translation.notes
        .map((note) => note.comment.trim())
        .where((comment) => comment.isNotEmpty && !_looksLikeEnglish(comment))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).notes,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (notes.isEmpty)
          const Text('Não há observações adicionais em português para este exercício.')
        else
          ...notes.map((note) => Text(note)),
        const SizedBox(height: 9),
      ],
    );
  }
}
