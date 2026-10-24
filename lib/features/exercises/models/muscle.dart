/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:wger/core/i18n.dart';

class Muscle extends Equatable {
  final int id;
  final String name;
  final String nameEn;
  final bool isFront;

  const Muscle({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.isFront,
  });

  @override
  List<Object?> get props => [id, name, isFront];

  static const Map<String, String> _nomesPt = {
    'external obliques': 'Oblíquos externos',
    'internal obliques': 'Oblíquos internos',
    'rectus abdominis': 'Reto abdominal',
    'abs': 'Abdômen',
    'abdominals': 'Abdômen',
    'pectoralis major': 'Peitoral maior',
    'pectoralis minor': 'Peitoral menor',
    'biceps brachii': 'Bíceps',
    'triceps brachii': 'Tríceps',
    'deltoid': 'Deltoides',
    'quadriceps femoris': 'Quadríceps',
    'hamstrings': 'Posteriores da coxa',
    'gluteus maximus': 'Glúteo máximo',
    'gluteus medius': 'Glúteo médio',
    'gastrocnemius': 'Gastrocnêmio',
    'soleus': 'Sóleo',
    'latissimus dorsi': 'Grande dorsal',
    'trapezius': 'Trapézio',
    'erector spinae': 'Eretores da coluna',
    'brachialis': 'Braquial',
    'brachioradialis': 'Braquiorradial',
    'forearms': 'Antebraços',
    'quadriceps': 'Quadríceps',
    'glutes': 'Glúteos',
    'calves': 'Panturrilhas',
  };

  String nameTranslated(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    if (language == 'pt') {
      final english = nameEn.trim().toLowerCase();
      final portuguese = _nomesPt[english];
      if (portuguese != null) return portuguese;
      if (name.trim().isNotEmpty && !name.trim().toLowerCase().contains(RegExp(r'^(external|internal|rectus|pectoralis|biceps|triceps|deltoid|quadriceps|gluteus|gastrocnemius|soleus|latissimus|trapezius|erector)'))) {
        return name;
      }
      return name;
    }
    return name;
  }

  @override
  String toString() {
    return 'Muscle: $id - $name';
  }
}
