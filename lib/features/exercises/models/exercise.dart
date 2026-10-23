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
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/language.dart';
import 'package:wger/features/exercises/models/category.dart';
import 'package:wger/features/exercises/models/equipment.dart';
import 'package:wger/features/exercises/models/image.dart';
import 'package:wger/features/exercises/models/muscle.dart';
import 'package:wger/features/exercises/models/translation.dart';
import 'package:wger/features/exercises/models/video.dart';

class Exercise extends Equatable {
  static final _logger = Logger('ExerciseModel');

  final int id;
  final String uuid;
  final String? variationGroup;
  final DateTime? created;
  final DateTime? lastUpdate;
  final ExerciseCategory category;
  final List<Muscle> muscles;
  final List<Muscle> musclesSecondary;
  final List<Equipment> equipment;
  final List<ExerciseImage> images;
  final List<Translation> translations;
  final List<Video> videos;
  final List<String> authors;
  final List<String> authorsGlobal;

  int get categoryId => category.id;
  List<int> get musclesIds => muscles.map((e) => e.id).toList();
  List<int> get musclesSecondaryIds => musclesSecondary.map((e) => e.id).toList();
  List<int> get equipmentIds => equipment.map((e) => e.id).toList();

  const Exercise({
    required this.id,
    required this.uuid,
    this.created,
    this.lastUpdate,
    this.variationGroup,
    required this.category,
    this.muscles = const [],
    this.musclesSecondary = const [],
    this.equipment = const [],
    this.images = const [],
    this.translations = const [],
    this.videos = const [],
    this.authors = const [],
    this.authorsGlobal = const [],
  });

  Exercise copyWith({
    int? id,
    String? uuid,
    DateTime? created,
    DateTime? lastUpdate,
    String? variationGroup,
    ExerciseCategory? category,
    List<Muscle>? muscles,
    List<Muscle>? musclesSecondary,
    List<Equipment>? equipment,
    List<ExerciseImage>? images,
    List<Translation>? translations,
    List<Video>? videos,
    List<String>? authors,
    List<String>? authorsGlobal,
  }) {
    return Exercise(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      created: created ?? this.created,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      variationGroup: variationGroup ?? this.variationGroup,
      category: category ?? this.category,
      muscles: muscles ?? this.muscles,
      musclesSecondary: musclesSecondary ?? this.musclesSecondary,
      equipment: equipment ?? this.equipment,
      images: images ?? this.images,
      translations: translations ?? this.translations,
      videos: videos ?? this.videos,
      authors: authors ?? this.authors,
      authorsGlobal: authorsGlobal ?? this.authorsGlobal,
    );
  }

  bool get showPlateCalculator => equipment.map((e) => e.id).contains(ID_EQUIPMENT_BARBELL);

  /// Returns the translation for the given language.
  ///
  /// Falls back to English, then to any available translation. If the exercise
  /// has no translations at all, an empty placeholder in the requested language
  /// is returned so callers never have to handle a missing translation. This
  /// happens transiently while translations are still syncing, or for exercises
  /// that genuinely ship without any translation.
  // Nomes usuais nas academias brasileiras para exercícios sem tradução pt.
  // A correspondência é exata para evitar trocar nomes de variações diferentes.
  static const Map<String, String> _brazilianExerciseNames = {
    'bench press': 'Supino reto',
    'barbell bench press': 'Supino reto com barra',
    'dumbbell bench press': 'Supino reto com halteres',
    'incline bench press': 'Supino inclinado',
    'decline bench press': 'Supino declinado',
    'push up': 'Flexão de braços',
    'push-up': 'Flexão de braços',
    'squat': 'Agachamento',
    'barbell squat': 'Agachamento com barra',
    'bodyweight squat': 'Agachamento livre',
    'leg press': 'Leg press',
    'leg extension': 'Cadeira extensora',
    'leg curl': 'Mesa flexora',
    'deadlift': 'Levantamento terra',
    'romanian deadlift': 'Levantamento terra romeno',
    'lat pulldown': 'Puxada alta',
    'pull up': 'Barra fixa',
    'pull-up': 'Barra fixa',
    'seated cable row': 'Remada baixa na polia',
    'bicep curl': 'Rosca bíceps',
    'barbell curl': 'Rosca direta com barra',
    'hammer curl': 'Rosca martelo',
    'triceps pushdown': 'Tríceps na polia',
    'shoulder press': 'Desenvolvimento de ombros',
    'lateral raise': 'Elevação lateral',
    'calf raise': 'Elevação de panturrilhas',
    'plank': 'Prancha abdominal',
    'crunch': 'Abdominal curto',
    'incline dumbbell press': 'Supino inclinado com halteres',
    'incline barbell bench press': 'Supino inclinado com barra',
    'decline dumbbell bench press': 'Supino declinado com halteres',
    'chest fly': 'Crucifixo',
    'dumbbell fly': 'Crucifixo com halteres',
    'cable crossover': 'Crossover na polia',
    'chest press': 'Supino na máquina',
    'pec deck': 'Voador peitoral',
    'butterfly': 'Voador peitoral',
    'dips': 'Paralelas',
    'triceps dips': 'Mergulho para tríceps',
    'close grip bench press': 'Supino fechado',
    'skull crushers': 'Tríceps testa',
    'overhead triceps extension': 'Tríceps francês',
    'triceps extension': 'Extensão de tríceps',
    'preacher curl': 'Rosca Scott',
    'concentration curl': 'Rosca concentrada',
    'incline dumbbell curl': 'Rosca inclinada com halteres',
    'reverse curl': 'Rosca inversa',
    'front raise': 'Elevação frontal',
    'rear delt fly': 'Crucifixo inverso',
    'reverse fly': 'Crucifixo inverso',
    'arnold press': 'Desenvolvimento Arnold',
    'upright row': 'Remada alta',
    'shrugs': 'Encolhimento de ombros',
    'dumbbell shrug': 'Encolhimento com halteres',
    'barbell row': 'Remada curvada com barra',
    'bent over row': 'Remada curvada',
    'one arm dumbbell row': 'Remada unilateral com halter',
    't-bar row': 'Remada cavalinho',
    'cable row': 'Remada na polia',
    'straight arm pulldown': 'Pulldown com braços estendidos',
    'chin up': 'Barra fixa supinada',
    'hyperextensions': 'Extensão lombar',
    'back extension': 'Extensão lombar',
    'good morning': 'Bom dia com barra',
    'front squat': 'Agachamento frontal',
    'goblet squat': 'Agachamento goblet',
    'sumo squat': 'Agachamento sumô',
    'bulgarian split squat': 'Agachamento búlgaro',
    'lunges': 'Avanço',
    'lunge': 'Avanço',
    'walking lunges': 'Avanço caminhando',
    'step up': 'Subida no banco',
    'hip thrust': 'Elevação pélvica',
    'glute bridge': 'Ponte de glúteos',
    'hip abduction': 'Abdução de quadril',
    'hip adduction': 'Adução de quadril',
    'seated leg curl': 'Cadeira flexora',
    'lying leg curl': 'Mesa flexora',
    'standing calf raise': 'Panturrilha em pé',
    'seated calf raise': 'Panturrilha sentado',
    'hack squat': 'Agachamento hack',
    'stiff leg deadlift': 'Stiff',
    'stiff-legged deadlift': 'Stiff',
    'sumo deadlift': 'Levantamento terra sumô',
    'kettlebell swing': 'Balanço com kettlebell',
    'mountain climbers': 'Escalador',
    'jumping jacks': 'Polichinelos',
    'burpees': 'Burpees',
    'bicycle crunch': 'Abdominal bicicleta',
    'reverse crunch': 'Abdominal reverso',
    'leg raises': 'Elevação de pernas',
    'hanging leg raise': 'Elevação de pernas suspenso',
    'russian twist': 'Rotação russa',
    'side plank': 'Prancha lateral',
  };

  Translation _localizeFallback(Translation original, String languageCode) {
    if (languageCode != 'pt' || original.language.shortName.toLowerCase().startsWith('pt')) {
      return original;
    }
    final localizedName = _brazilianExerciseNames[original.name.trim().toLowerCase()];
    if (localizedName == null) return original;
    return Translation(
      id: original.id,
      uuid: original.uuid,
      created: original.created,
      exerciseId: original.exerciseId,
      name: localizedName,
      description: original.description,
      descriptionSource: original.descriptionSource,
      language: original.language,
      notes: original.notes,
      aliases: original.aliases,
    );
  }

  Translation getTranslation(String language) {
    // If the language is in the form en-US, take the language code only
    final languageCode = language.replaceAll('_', '-').split('-')[0].toLowerCase();

    if (translations.isEmpty) {
      _logger.info('Exercise-ID $id has no translations, returning an empty placeholder.');
      return Translation(
        name: '',
        description: '',
        language: Language(id: -1, shortName: languageCode, fullName: ''),
      );
    }

    final selected = translations.firstWhere(
      (e) => e.language.shortName.replaceAll('_', '-').split('-')[0].toLowerCase() == languageCode,
      orElse: () => translations.firstWhere(
        (e) => e.language.shortName == LANGUAGE_SHORT_ENGLISH,
        orElse: () {
          _logger.info(
            'Could not find fallback english translation for exercise-ID $id, returning '
            'first language (${translations.first.language.shortName}) instead.',
          );
          return translations.first;
        },
      ),
    );
    return _localizeFallback(selected, languageCode);
  }

  ExerciseImage? get getMainImage {
    return images.firstWhereOrNull((image) => image.isMain);
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    created,
    lastUpdate,
    category,
    equipment,
    muscles,
    musclesSecondary,
  ];
}
