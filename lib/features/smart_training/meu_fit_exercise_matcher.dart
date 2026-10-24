import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/smart_training/starter_workout_planner.dart';

/// Corresponde sugestões aos exercícios existentes no catálogo sincronizado.
/// Não inventa IDs nem cria exercícios novos.
class MeuFitExerciseMatch {
  const MeuFitExerciseMatch(this.planned, this.exercise);
  final PlannedExercise planned;
  final Exercise? exercise;
  bool get found => exercise != null;
}

class MeuFitExerciseMatcher {
  const MeuFitExerciseMatcher();

  static const Map<String, List<String>> _aliases = {
    'Supino na máquina': ['supino na máquina', 'chest press'],
    'Remada sentada': ['remada sentada', 'seated cable row', 'cable row'],
    'Desenvolvimento na máquina': ['desenvolvimento na máquina', 'shoulder press'],
    'Elevação pélvica': ['elevação pélvica', 'hip thrust'],
    'Mesa flexora': ['mesa flexora', 'lying leg curl', 'leg curl'],
    'Leg press': ['leg press'],
    'Prancha': ['prancha', 'plank'],
    'Extensão alternada de braço e perna': ['bird dog', 'bird-dog', 'extensão alternada de braço e perna'],
    'Flexão inclinada': ['flexão inclinada', 'incline push up', 'incline push-up'],
    'Remada com elástico': ['remada com elástico', 'resistance band row'],
    'Desenvolvimento com elástico': ['desenvolvimento com elástico', 'band shoulder press'],
    'Ponte de glúteos': ['ponte de glúteos', 'glute bridge'],
    'Levantamento terra com mochila': ['levantamento terra com mochila', 'backpack deadlift'],
    'Agachamento até uma cadeira': ['agachamento até uma cadeira', 'chair squat'],
  };

  String _normalize(String text) => text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  List<MeuFitExerciseMatch> match(
    List<PlannedExercise> planned,
    List<Exercise> catalog,
  ) {
    final usedIds = <int>{};
    return planned.map((item) {
      final names = _aliases[item.name] ?? [item.name];
      Exercise? found;
      for (final alias in names) {
        final expected = _normalize(alias);
        for (final exercise in catalog) {
          if (usedIds.contains(exercise.id)) continue;
          final translations = [
            exercise.getTranslation('pt').name,
            exercise.getTranslation('en').name,
          ];
          if (translations.any((name) => _normalize(name) == expected)) {
            found = exercise;
            break;
          }
        }
        if (found != null) break;
      }
      if (found != null) usedIds.add(found.id);
      return MeuFitExerciseMatch(item, found);
    }).toList(growable: false);
  }
}
