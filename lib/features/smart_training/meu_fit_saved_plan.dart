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

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Formato inválido');

      final plan = <PlannedWorkout>[];
      for (final value in decoded) {
        if (value is! Map<String, dynamic> ||
            value['title'] is! String ||
            value['exercises'] is! List) {
          throw const FormatException('Dia de treino inválido');
        }

        final exercises = <PlannedExercise>[];
        for (final item in value['exercises'] as List) {
          if (item is! Map<String, dynamic> ||
              item['name'] is! String ||
              item['sets'] is! num ||
              item['reps'] is! String ||
              item['restSeconds'] is! num) {
            throw const FormatException('Exercício inválido');
          }

          final sets = (item['sets'] as num).toInt();
          final restSeconds = (item['restSeconds'] as num).toInt();
          if (sets < 1 || restSeconds < 0) {
            throw const FormatException('Séries ou descanso inválidos');
          }

          exercises.add(PlannedExercise(
            item['name'] as String,
            sets,
            item['reps'] as String,
            restSeconds,
          ));
        }

        plan.add(PlannedWorkout(value['title'] as String, exercises));
      }
      return plan;
    } on FormatException {
      await prefs.remove(_key);
      return null;
    } on TypeError {
      await prefs.remove(_key);
      return null;
    }
  }
}
