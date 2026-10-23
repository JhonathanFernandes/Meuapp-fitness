/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
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

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wger/features/nutrition/models/ingredient.dart';
import 'package:wger/features/nutrition/screens/ingredient_detail_screen.dart';
import 'package:wger/features/nutrition/widgets/ingredient_images.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class IngredientListTile extends StatelessWidget {
  const IngredientListTile({super.key, required this.ingredient});

  final Ingredient ingredient;

  Future<void> _openSource(BuildContext context) async {
    final url = ingredient.sourceUrl;
    if (url == null || url.trim().isEmpty) return;
    final opened = await launchUrl(
      Uri.tryParse(url) ?? Uri(),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a fonte do alimento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    const double imgSize = 60;
    final String macros =
        'P: ${ingredient.protein}g / C: ${ingredient.carbohydrates}g / G: ${ingredient.fat}g';
    final sourceName = ingredient.sourceName?.trim();
    final hasSource = sourceName != null && sourceName.isNotEmpty;
    final hasSourceUrl = ingredient.sourceUrl?.trim().isNotEmpty ?? false;

    return ListTile(
      leading: SizedBox(
        height: imgSize,
        width: imgSize,
        child: CircleAvatar(
          backgroundColor: const Color(0x00ffffff),
          child: ClipOval(
            child: SizedBox(
              height: imgSize,
              width: imgSize,
              child: IngredientImageWidget(image: ingredient.image),
            ),
          ),
        ),
      ),
      title: Text(ingredient.name, overflow: TextOverflow.ellipsis, maxLines: 2),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${i18n.kcalValue(ingredient.energy.toString())} • $macros / 100 g',
            overflow: TextOverflow.ellipsis,
          ),
          if (hasSource)
            Text(
              'Fonte: $sourceName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Text(
              'Fonte nutricional não informada',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
      trailing: hasSourceUrl
          ? IconButton(
              tooltip: 'Abrir fonte nutricional',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openSource(context),
            )
          : null,
      onTap: () {
        Navigator.pushNamed(
          context,
          IngredientDetailScreen.routeName,
          arguments: ingredient.id,
        );
      },
    );
  }
}
