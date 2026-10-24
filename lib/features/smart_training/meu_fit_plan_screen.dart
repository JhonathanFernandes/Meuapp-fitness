import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/smart_training/meu_fit_exercise_matcher.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';
import 'package:wger/features/smart_training/starter_workout_planner.dart';
import 'package:wger/features/smart_training/meu_fit_saved_plan.dart';

/// Prévia de treino sugerido com base nas respostas do cadastro.
class MeuFitPlanScreen extends ConsumerWidget {
  const MeuFitPlanScreen({super.key, required this.profile, required this.onContinue});

  final MeuFitOnboardingProfile profile;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lime = Color(0xFFC9F31D);
    const background = Color(0xFF101010);
    const surface = Color(0xFF242424);
    final requiresIndividualReview = profile.age < 18 || profile.age > 64 || profile.hasPhysicalLimitations;
    final plan = requiresIndividualReview ? const <PlannedWorkout>[] : const StarterWorkoutPlanner().generate(
      TrainingProfile(
        age: profile.age, weightKg: profile.weightKg, heightCm: profile.heightCm,
        daysPerWeek: profile.daysPerWeek,
        goal: switch (profile.goal) {
          'ganhar_massa' => FitnessGoal.buildMuscle,
          'manter_forma' => FitnessGoal.stayFit,
          'flexibilidade' => FitnessGoal.flexibility,
          _ => FitnessGoal.loseWeight,
        },
        experience: switch (profile.experience) {
          'avancado' => TrainingExperience.advanced,
          'intermediario' => TrainingExperience.intermediate,
          _ => TrainingExperience.beginner,
        },
        location: profile.trainingLocation == 'casa' ? TrainingLocation.home : TrainingLocation.gym,
        avoidKneeImpact: profile.hasPhysicalLimitations,
      ),
    );

    final explanation = switch (profile.goal) {
      'emagrecer' => 'O plano combina fortalecimento e atividade física para apoiar o emagrecimento. O resultado também depende da alimentação, recuperação e regularidade.',
      'ganhar_massa' => 'O plano prioriza exercícios de força. A evolução depende de progressão gradual, alimentação adequada e descanso.',
      'flexibilidade' => 'O plano dá prioridade à mobilidade e aos alongamentos controlados. Não force amplitudes nem continue um movimento que cause dor.',
      _ => 'O plano busca melhorar o condicionamento e manter uma rotina equilibrada, com progressão gradual.',
    };
    final catalog = ref.watch(exercisesProvider);

    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(primary: lime, surface: surface),
        appBarTheme: const AppBarTheme(backgroundColor: background, foregroundColor: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Seu plano de treino'), automaticallyImplyLeading: false, elevation: 0),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: lime.withValues(alpha: 0.35))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MEU FIT · PLANO INICIAL', style: TextStyle(color: lime, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  const Text('Seu treino, organizado por dia', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text('${profile.daysPerWeek} dias por semana · ${profile.trainingLocation == 'casa' ? 'Em casa' : 'Na academia'}'),
                  const SizedBox(height: 8),
                  Text(explanation, style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 20),
              if (requiresIndividualReview)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
                  child: const Text('Pelas respostas informadas, é importante receber orientação individual de um profissional de Educação Física antes de seguir um treino personalizado. Por segurança, não foi gerada uma rotina automática.', style: TextStyle(color: Colors.orangeAccent)),
                )
              else if (plan.isEmpty)
                const Text('Não foi possível montar uma sugestão de treino para estas respostas.')
              else
                for (var index = 0; index < plan.length; index++)
                  _WorkoutDayCard(dayNumber: index + 1, workout: plan[index], catalog: catalog),
              const SizedBox(height: 8),
              const Text('Esta é uma sugestão inicial, não uma prescrição profissional. Ajuste os exercícios à sua condição e interrompa qualquer movimento que cause dor.', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 18),
              if (!requiresIndividualReview)
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await MeuFitSavedPlan().save(plan);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plano salvo neste celular.')));
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar o plano.')));
                    }
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Salvar meu plano'),
                  style: OutlinedButton.styleFrom(foregroundColor: lime, side: const BorderSide(color: lime)),
                ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 17)),
                child: const Text('Ir para o aplicativo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutDayCard extends StatelessWidget {
  const _WorkoutDayCard({required this.dayNumber, required this.workout, required this.catalog});
  final int dayNumber;
  final PlannedWorkout workout;
  final dynamic catalog;

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    const surface = Color(0xFF242424);
    final matches = catalog.value == null ? null : const MeuFitExerciseMatcher().match(workout.exercises, catalog.value!.exercises);

    return Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42, height: 42, alignment: Alignment.center,
              decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(13)),
              child: Text('$dayNumber', style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DIA $dayNumber', style: const TextStyle(color: lime, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 3),
              Text(workout.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ])),
          ]),
          const Divider(height: 26, color: Colors.white12),
          if (matches == null)
            Text(catalog.hasError ? 'Biblioteca de exercícios indisponível agora; confira novamente mais tarde.' : 'Carregando detalhes dos exercícios…', style: const TextStyle(color: Colors.white70))
          else
            for (final match in matches)
              Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.fitness_center, size: 18, color: lime),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(match.planned.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('${match.planned.sets} séries × ${match.planned.reps} repetições', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Descanso: ${match.planned.restSeconds} segundos', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ])),
                ]),
              ),
        ]),
      ),
    );
  }
}
