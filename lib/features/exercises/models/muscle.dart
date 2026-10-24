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
    if (language != 'pt') return name;

    final englishName = nameEn.trim().toLowerCase();
    final currentName = name.trim().toLowerCase();
    final translated = _nomesPt[englishName] ?? _nomesPt[currentName];
    if (translated != null) return translated;

    // Nomes anatômicos adicionais comuns no catálogo wger.
    const additional = <String, String>{
      'anterior deltoid': 'Deltoide anterior',
      'posterior deltoid': 'Deltoide posterior',
      'middle deltoid': 'Deltoide lateral',
      'deltoids': 'Deltoides',
      'pectorals': 'Peitorais',
      'chest': 'Peitoral',
      'abdominal obliques': 'Oblíquos abdominais',
      'transverse abdominis': 'Transverso do abdômen',
      'serratus anterior': 'Serrátil anterior',
      'rhomboids': 'Romboides',
      'infraspinatus': 'Infraespinal',
      'supraspinatus': 'Supraespinal',
      'teres major': 'Redondo maior',
      'teres minor': 'Redondo menor',
      'lower back': 'Lombar',
      'upper back': 'Parte superior das costas',
      'spine': 'Coluna vertebral',
      'neck': 'Pescoço',
      'adductors': 'Adutores',
      'abductors': 'Abdutores',
      'hip flexors': 'Flexores do quadril',
      'iliopsoas': 'Iliopsoas',
      'tibialis anterior': 'Tibial anterior',
      'forearm extensors': 'Extensores do antebraço',
      'forearm flexors': 'Flexores do antebraço',
      'wrist flexors': 'Flexores do punho',
      'wrist extensors': 'Extensores do punho',
      'gluteus': 'Glúteos',
      'quadratus lumborum': 'Quadrado lombar',
    };
    final additionalTranslation = additional[englishName] ?? additional[currentName];
    if (additionalTranslation != null) return additionalTranslation;

    if (name.isNotEmpty &&
        !RegExp(r'\b(external|internal|rectus|pectoralis|biceps|triceps|deltoid|quadriceps|gluteus|gastrocnemius|soleus|latissimus|trapezius|erector|anterior|posterior|middle|serratus|rhomboids|infraspinatus|supraspinatus|teres|adductors|abductors|hamstrings|calves|forearms)\b', caseSensitive: false).hasMatch(name)) {
      return name;
    }

    // Não exibe a denominação anatômica em inglês quando o catálogo não traz
    // uma tradução reconhecida.
    return 'Músculo não identificado em português';
  }

  @override
  String toString() {
    return 'Muscle: $id - $name';
  }
}
