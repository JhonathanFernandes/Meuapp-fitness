import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wger/features/smart_training/starter_workout_planner.dart';

/// Cópia local do plano sugerido. Não altera as rotinas do servidor wger.
class MeuFitSavedPlan {
  static const _key = 'meu_fit_saved_plan_v1';

  Future<void> save(List<PlannedWorkout> plan) async {
    if (plan.isEmpty || plan.every((day) => day.exercises.isEmpty)) {
      throw StateError('Não há exercícios para salvar.');
    }
    final data = plan.map((day) => {
      'title': day.title,
      'exercises': day.exercises.map((exercise) => {
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'restSeconds': exercise.restSeconds,
      }).toList(),
    }).toList();
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, jsonEncode(data))) {
      throw StateError('Não foi possível salvar o plano.');
    }
  }

  Future<List<PlannedWorkout>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((value) {
      final day = value as Map<String, dynamic>;
      final exercises = (day['exercises'] as List<dynamic>).map((item) {
        final exercise = item as Map<String, dynamic>;
        return PlannedExercise(
          exercise['name'] as String,
          (exercise['sets'] as num).toInt(),
          exercise['reps'] as String,
          (exercise['restSeconds'] as num).toInt(),
        );
      }).toList();
      return PlannedWorkout(day['title'] as String, exercises);
    }).toList();
  }
}
