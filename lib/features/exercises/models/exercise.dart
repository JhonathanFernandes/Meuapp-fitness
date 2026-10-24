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

  // Instruções curtas em português para os exercícios usados pelo plano Meu Fit.
  // São exibidas quando o catálogo não possui descrição traduzida para pt.
  static const Map<String, String> _brazilianExerciseDescriptions = {
    'chest press': '<p>Mantenha as costas apoiadas e os pés firmes. Empurre as alças para a frente de forma controlada, sem travar os cotovelos, e retorne lentamente.</p>',
    'seated cable row': '<p>Mantenha o tronco estável e os ombros afastados das orelhas. Puxe a alça em direção ao abdômen, aproxime as escápulas e volte devagar sem balançar o corpo.</p>',
    'cable row': '<p>Mantenha o tronco estável. Puxe a alça em direção ao corpo, aproximando as escápulas, e retorne lentamente sem usar impulso.</p>',
    'shoulder press': '<p>Comece com as mãos na altura dos ombros. Empurre para cima sem arquear a lombar e retorne devagar, sem travar os cotovelos.</p>',
    'hip thrust': '<p>Apoie as costas em um banco e mantenha os pés firmes. Eleve o quadril contraindo os glúteos, sem exagerar na curvatura lombar, e desça com controle.</p>',
    'lying leg curl': '<p>Ajuste o equipamento para que o eixo fique alinhado ao joelho. Flexione os joelhos controlando a carga e retorne sem deixar o peso despencar.</p>',
    'leg press': '<p>Mantenha as costas apoiadas e os pés firmes na plataforma. Flexione os joelhos até uma amplitude confortável e empurre sem travá-los.</p>',
    'plank': '<p>Apoie os antebraços e as pontas dos pés, mantenha o corpo alinhado e contraia o abdômen. Respire normalmente e encerre se perder a postura.</p>',
    'incline push up': '<p>Apoie as mãos em uma superfície firme e elevada, mantenha o corpo alinhado e flexione os cotovelos devagar. Empurre a superfície para voltar à posição inicial.</p>',
    'incline push-up': '<p>Apoie as mãos em uma superfície firme e elevada, mantenha o corpo alinhado e flexione os cotovelos devagar. Empurre a superfície para voltar à posição inicial.</p>',
    'glute bridge': '<p>Deite-se de costas, flexione os joelhos e mantenha os pés apoiados. Eleve o quadril contraindo os glúteos e desça lentamente.</p>',
    'deadlift': '<p>Mantenha a carga próxima ao corpo, leve o quadril para trás e preserve a coluna em posição neutra. Suba com controle e retorne levando o quadril para trás.</p>',
    'backpack deadlift': '<p>Segure a mochila próxima ao corpo, leve o quadril para trás e mantenha a coluna neutra. Suba com controle e retorne devagar.</p>',
    'bodyweight squat': '<p>Afaste os pés aproximadamente na largura dos ombros. Leve o quadril para trás, flexione os joelhos mantendo os pés apoiados e suba com controle.</p>',
    'bird dog': '<p>Na posição de quatro apoios, estenda lentamente um braço e a perna oposta. Evite girar o quadril, retorne e alterne os lados.</p>',
  };

  static const Map<String, String> _additionalBrazilianExerciseNames = {
    'bird dog': 'Extensão alternada de braço e perna',
    'bird-dog': 'Extensão alternada de braço e perna',
    'horizontal plank': 'Prancha horizontal',
    'forearm plank': 'Prancha com antebraços',
    'side plank': 'Prancha lateral',
    'incline plank': 'Prancha inclinada',
    'reverse plank': 'Prancha invertida',
    'dead bug': 'Abdominal com braços e pernas alternados',
    'superman': 'Extensão de braços e pernas deitado',
    'wall sit': 'Agachamento isométrico na parede',
    'box jump': 'Salto na caixa',
    'high knees': 'Corrida com joelhos elevados',
    'butt kicks': 'Corrida com calcanhares elevados',
    'bear crawl': 'Deslocamento em posição de urso',
    'donkey kick': 'Extensão de quadril em quatro apoios',
    'fire hydrant': 'Abdução de quadril em quatro apoios',
    'clam shell': 'Abertura de quadril deitado de lado',
    'clamshell': 'Abertura de quadril deitado de lado',
    'hip hinge': 'Dobradiça de quadril',
    'good morning': 'Bom dia com barra',
    'single leg deadlift': 'Levantamento terra unilateral',
    'single-leg deadlift': 'Levantamento terra unilateral',
    'romanian deadlift': 'Levantamento terra romeno',
    'dumbbell romanian deadlift': 'Levantamento terra romeno com halteres',
    'single leg glute bridge': 'Ponte de glúteos unilateral',
    'single-leg glute bridge': 'Ponte de glúteos unilateral',
    'standing leg curl': 'Flexão de joelho em pé',
    'seated leg extension': 'Cadeira extensora',
    'leg extension': 'Cadeira extensora',
    'lying leg curl': 'Mesa flexora',
    'seated leg curl': 'Cadeira flexora',
    'cable kickback': 'Coice de glúteo na polia',
    'glute kickback': 'Coice de glúteo',
    'hip circle': 'Círculos com o quadril',
    'hip circles': 'Círculos com o quadril',
    'standing hip abduction': 'Abdução de quadril em pé',
    'standing hip adduction': 'Adução de quadril em pé',
    'seated row': 'Remada sentada',
    'machine row': 'Remada na máquina',
    'chest supported row': 'Remada com peito apoiado',
    'chest-supported row': 'Remada com peito apoiado',
    'pendlay row': 'Remada Pendlay',
    'renegade row': 'Remada renegada',
    'face pull': 'Puxada para o rosto na polia',
    'lat prayer': 'Puxada alta com braços estendidos',
    'pullover': 'Pullover',
    'dumbbell pullover': 'Pullover com halter',
    'cable pullover': 'Pullover na polia',
    'assisted pull up': 'Barra fixa assistida',
    'assisted pull-up': 'Barra fixa assistida',
    'wide grip pull up': 'Barra fixa com pegada aberta',
    'wide-grip pull-up': 'Barra fixa com pegada aberta',
    'neutral grip pull up': 'Barra fixa com pegada neutra',
    'push press': 'Desenvolvimento com impulso',
    'landmine press': 'Desenvolvimento com barra apoiada',
    'dumbbell shoulder press': 'Desenvolvimento de ombros com halteres',
    'seated dumbbell press': 'Desenvolvimento sentado com halteres',
    'military press': 'Desenvolvimento militar',
    'cable lateral raise': 'Elevação lateral na polia',
    'dumbbell lateral raise': 'Elevação lateral com halteres',
    'lateral raises': 'Elevação lateral',
    'front raises': 'Elevação frontal',
    'reverse pec deck': 'Voador inverso',
    'cable fly': 'Crucifixo na polia',
    'low cable fly': 'Crucifixo na polia baixa',
    'high cable fly': 'Crucifixo na polia alta',
    'incline push up': 'Flexão de braços inclinada',
    'incline push-up': 'Flexão de braços inclinada',
    'decline push up': 'Flexão de braços declinada',
    'decline push-up': 'Flexão de braços declinada',
    'diamond push up': 'Flexão de braços com mãos próximas',
    'diamond push-up': 'Flexão de braços com mãos próximas',
    'knee push up': 'Flexão de braços com joelhos apoiados',
    'knee push-up': 'Flexão de braços com joelhos apoiados',
    'close grip push up': 'Flexão de braços com pegada fechada',
    'close-grip push-up': 'Flexão de braços com pegada fechada',
    'triceps kickback': 'Coice para tríceps',
    'bench dip': 'Mergulho no banco',
    'bench dips': 'Mergulho no banco',
    'wrist curl': 'Flexão de punhos',
    'reverse wrist curl': 'Extensão de punhos',
    'wrist extension': 'Extensão de punhos',
    'wrist flexion': 'Flexão de punhos',
    'standing calf raise': 'Elevação de panturrilhas em pé',
    'seated calf raise': 'Elevação de panturrilhas sentado',
    'donkey calf raise': 'Elevação de panturrilhas inclinado',
    'toe raises': 'Elevação da ponta dos pés',
    'tibialis raise': 'Elevação da ponta dos pés para tibial anterior',
    'sit up': 'Abdominal completo',
    'sit-up': 'Abdominal completo',
    'v up': 'Abdominal em V',
    'v-up': 'Abdominal em V',
    'toe touches': 'Abdominal tocando os pés',
    'heel touches': 'Abdominal tocando os calcanhares',
    'flutter kicks': 'Chutes alternados com pernas estendidas',
    'scissor kicks': 'Tesoura com as pernas',
    'leg tuck': 'Flexão de pernas ao tronco',
    'hollow body hold': 'Isometria em posição canoa',
    'hollow hold': 'Isometria em posição canoa',
    'mountain climber': 'Escalador',
    'mountain climbers': 'Escalador',
    'jumping jack': 'Polichinelo',
    'jumping jacks': 'Polichinelo',
    'skater jumps': 'Saltos laterais de patinador',
    'skater jump': 'Salto lateral de patinador',
    'step-up': 'Subida no banco',
    'step ups': 'Subida no banco',
    'walking lunge': 'Avanço caminhando',
    'reverse lunge': 'Avanço para trás',
    'reverse lunges': 'Avanço para trás',
    'curtsy lunge': 'Avanço cruzado',
    'curtsy lunges': 'Avanço cruzado',
    'split squat': 'Agachamento dividido',
    'bulgarian split squat': 'Agachamento búlgaro',
    'sumo deadlift': 'Levantamento terra sumô',
    'kettlebell deadlift': 'Levantamento terra com kettlebell',
    'kettlebell swing': 'Balanço com kettlebell',
    'thruster': 'Agachamento com desenvolvimento',
    'wall push up': 'Flexão de braços na parede',
    'wall push-up': 'Flexão de braços na parede',
    'arm circles': 'Círculos com os braços',
    'shoulder circles': 'Círculos com os ombros',
    'torso rotation': 'Rotação de tronco',
    'standing side bend': 'Inclinação lateral do tronco em pé',
    'side bend': 'Inclinação lateral do tronco',
    'back extension': 'Extensão lombar',
    'hyperextension': 'Extensão lombar',
    'hyperextensions': 'Extensão lombar',
  };

  static const Map<String, String> _portugueseMovementWords = {
    'dumbbell': 'com halteres',
    'dumbbells': 'com halteres',
    'barbell': 'com barra',
    'cable': 'na polia',
    'machine': 'na máquina',
    'seated': 'sentado',
    'standing': 'em pé',
    'lying': 'deitado',
    'incline': 'inclinado',
    'decline': 'declinado',
    'reverse': 'inverso',
    'front': 'frontal',
    'lateral': 'lateral',
    'single leg': 'unilateral',
    'one arm': 'unilateral',
    'alternating': 'alternado',
    'alternate': 'alternado',
    'wide grip': 'com pegada aberta',
    'close grip': 'com pegada fechada',
    'narrow grip': 'com pegada fechada',
    'overhead': 'acima da cabeça',
    'bent over': 'curvado',
    'bodyweight': 'com peso corporal',
    'resistance band': 'com faixa elástica',
    'band': 'com elástico',
    'row': 'remada',
    'press': 'desenvolvimento',
    'raise': 'elevação',
    'curl': 'flexão',
    'extension': 'extensão',
    'squat': 'agachamento',
    'lunge': 'avanço',
    'plank': 'prancha',
    'crunch': 'abdominal',
    'fly': 'crucifixo',
    'pulldown': 'puxada',
    'pull up': 'barra fixa',
    'push up': 'flexão de braços',
    'deadlift': 'levantamento terra',
    'calf': 'panturrilha',
    'glute': 'glúteo',
    'hip': 'quadril',
    'leg': 'perna',
    'arm': 'braço',
    'shoulder': 'ombro',
    'chest': 'peitoral',
    'back': 'costas',
    'biceps': 'bíceps',
    'triceps': 'tríceps',
    'abdominal': 'abdominal',
  };

  bool _looksLikeEnglish(String value) {
    final text = value.toLowerCase();
    return RegExp(r'\b(with|and|for|from|the|to|your|keep|hold|slowly|start|return|alternate|added|stability|muscles|rectus|obliques|plank|bird dog|leg curl|hip thrust|incline|decline|standing|seated|lying|dumbbell|barbell|cable|machine|push up|pull down|deadlift|squat|crunch|row|press|raise|curl|extension)\b')
        .hasMatch(text);
  }

  String _translateExerciseNameByTerms(String originalName) {
    if (originalName.trim().isEmpty) return 'Exercício $id';
    var translated = originalName.toLowerCase();
    final entries = _portugueseMovementWords.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      translated = translated.replaceAll(
        RegExp(r'\\b' + RegExp.escape(entry.key) + r'\\b', caseSensitive: false),
        entry.value,
      );
    }
    if (translated == originalName.toLowerCase() || _looksLikeEnglish(translated)) {
      return 'Exercício $id';
    }
    return translated[0].toUpperCase() + translated.substring(1);
  }

  Translation _localizeFallback(Translation original, String languageCode) {
    if (languageCode != 'pt') return original;

    final originalName = original.name.trim();
    final key = originalName.toLowerCase();
    final localizedName = _brazilianExerciseNames[key] ??
        _additionalBrazilianExerciseNames[key];
    final sourceDescription = original.description.trim();
    final localizedDescription = _brazilianExerciseDescriptions[key];
    final shouldReplaceDescription = _looksLikeEnglish(sourceDescription);
    final description = localizedDescription ??
        (sourceDescription.isEmpty || shouldReplaceDescription
            ? '<p>Execute o movimento de forma controlada, mantenha a postura alinhada e use uma amplitude confortável. Consulte a demonstração visual quando disponível e interrompa se sentir dor.</p>'
            : original.description);

    // Mesmo quando o catálogo marca o texto como português, ele pode conter
    // termos em inglês ou estar parcialmente traduzido. Evita exibir esses
    // trechos crus na interface em português.
    final name = localizedName ??
        (original.language.shortName.toLowerCase().startsWith('pt') &&
                !_looksLikeEnglish(originalName)
            ? originalName
            : _translateExerciseNameByTerms(originalName));

    return Translation(
      id: original.id,
      uuid: original.uuid,
      created: original.created,
      exerciseId: original.exerciseId,
      name: name,
      description: description,
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
      _logger.info('Exercise-ID $id has no translations, returning a Portuguese-safe placeholder.');
      return _localizeFallback(
        Translation(
          name: '',
          description: '',
          language: Language(id: -1, shortName: languageCode, fullName: ''),
        ),
        languageCode,
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
