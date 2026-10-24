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
import 'package:url_launcher/url_launcher.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/widgets/exercises.dart';

class ImagesSection extends StatelessWidget {
  final Exercise exercise;

  const ImagesSection({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final muscleNames = exercise.muscles
        .map((muscle) => muscle.nameTranslated(context))
        .join(' ');
    final exerciseName =
        exercise.getTranslation(Localizations.localeOf(context).languageCode).name;
    final query = [exerciseName, muscleNames]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    final uri = Uri.https('www.google.com', '/search', {
      'tbm': 'isch',
      'q': '$query exercício demonstração',
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Imagem do exercício',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (exercise.images.isNotEmpty)
            CarouselImages(images: exercise.images)
          else ...[
            const Text('Ainda não há foto deste exercício no catálogo.'),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.image_search_outlined),
              label: const Text('Buscar imagens do exercício na internet'),
            ),
          ],
          const SizedBox(height: 9),
        ],
      ),
    );
  }
}
