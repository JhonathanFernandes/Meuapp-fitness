import 'package:flutter/material.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';
import 'package:wger/features/smart_training/starter_workout_planner.dart';

/// Prévia de treino sugerido com base nas respostas do cadastro.
/// Nesta etapa, não cria nem altera rotinas existentes no servidor wger.
class MeuFitPlanScreen extends StatelessWidget {
  const MeuFitPlanScreen({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  final MeuFitOnboardingProfile profile;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final plan = const StarterWorkoutPlanner().generate(
      TrainingProfile(
        age: profile.age,
        weightKg: profile.weightKg,
        heightCm: profile.heightCm,
        daysPerWeek: profile.daysPerWeek,
        goal: switch (profile.goal) {
          'ganhar_massa' => FitnessGoal.buildMuscle,
          'manter_forma' => FitnessGoal.stayFit,
          _ => FitnessGoal.loseWeight,
        },
        experience: switch (profile.experience) {
          'avancado' => TrainingExperience.advanced,
          'intermediario' => TrainingExperience.intermediate,
          _ => TrainingExperience.beginner,
        },
        location: profile.trainingLocation == 'casa'
            ? TrainingLocation.home
            : TrainingLocation.gym,
        avoidKneeImpact: profile.hasPhysicalLimitations,
      ),
    );

    const lime = Color(0xFFC9F31D);
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(primary: lime),
        scaffoldBackgroundColor: const Color(0xFF101010),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu Fit · Seu treino'),
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF101010),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEU PLANO INICIAL',
                        style: TextStyle(
                            color: lime, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Um treino para começar',
                        style: TextStyle(
                            fontSize: 27, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Sugestão automática baseada nas suas respostas. '
                        'Ainda não foi adicionada ao calendário.'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: plan.length,
                  itemBuilder: (context, index) {
                    final day = plan[index];
                    return Card(
                      color: const Color(0xFF242424),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day.title,
                                style: const TextStyle(
                                    color: lime,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            for (final exercise in day.exercises)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• ${exercise.name} · ${exercise.sets} séries '
                                  '× ${exercise.reps}',
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Ir para o aplicativo'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
