import 'package:flutter/material.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';
import 'package:wger/features/smart_training/starter_workout_planner.dart';

/// Dashboard principal do Meu Fit, conectado ao perfil preenchido no primeiro acesso.
/// Mantém o nome/rota DashboardScreen para que HomeTabsScreen e links existentes
/// abram esta tela, em vez do painel antigo com widgets do Wger.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<MeuFitOnboardingProfile?> _profileFuture;

  static const _lime = Color(0xFFC9F31D);
  static const _background = Color(0xFF101010);
  static const _surface = Color(0xFF242424);

  @override
  void initState() {
    super.initState();
    _profileFuture = MeuFitOnboardingStorage().load();
  }

  String _goalLabel(String goal) => switch (goal) {
        'emagrecer' => 'Emagrecimento',
        'ganhar_massa' => 'Ganhar massa muscular',
        'manter_forma' => 'Manter a forma',
        'flexibilidade' => 'Flexibilidade e mobilidade',
        _ => 'Condicionamento físico',
      };

  String _experienceLabel(String experience) => switch (experience) {
        'iniciante' => 'Iniciante',
        'intermediario' => 'Intermediário',
        'avancado' => 'Avançado',
        _ => 'Não informado',
      };

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.dark(primary: _lime, surface: _surface),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu Fit · Painel'),
          backgroundColor: _background,
        ),
        body: FutureBuilder<MeuFitOnboardingProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: _lime),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Não foi possível carregar seu perfil. Tente abrir o aplicativo novamente.'),
                ),
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Seu perfil ainda não foi preenchido. Volte ao início para configurar seus objetivos.'),
                ),
              );
            }

            final requiresIndividualReview = profile.age < 18 ||
                profile.age > 64 ||
                profile.hasPhysicalLimitations;
            final plan = requiresIndividualReview
                ? const <PlannedWorkout>[]
                : const StarterWorkoutPlanner().generate(
                    TrainingProfile(
                      age: profile.age,
                      weightKg: profile.weightKg,
                      heightCm: profile.heightCm,
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
                      location: profile.trainingLocation == 'casa'
                          ? TrainingLocation.home
                          : TrainingLocation.gym,
                      avoidKneeImpact: profile.hasPhysicalLimitations,
                    ),
                  );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _lime.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SEU PAINEL PERSONALIZADO',
                        style: TextStyle(
                          color: _lime,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Objetivo: ${_goalLabel(profile.goal)}',
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('${profile.daysPerWeek} dias de treino por semana · ${_experienceLabel(profile.experience)}'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: '${profile.weightKg.toStringAsFixed(1)} kg'),
                          _InfoChip(label: '${profile.heightCm.toStringAsFixed(0)} cm'),
                          _InfoChip(label: profile.trainingLocation == 'casa' ? 'Treino em casa' : 'Treino na academia'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Seu plano de treino',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (requiresIndividualReview)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Pelo perfil informado, é necessária uma avaliação individual com profissional de Educação Física antes de apresentar um treino automático personalizado. Nenhuma rotina foi criada.',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                  )
                else if (plan.isEmpty)
                  const Text('Não foi possível gerar sugestões para este perfil no momento.')
                else
                  for (final day in plan)
                    Card(
                      color: _surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day.title,
                              style: const TextStyle(
                                color: _lime,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final exercise in day.exercises)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.fitness_center, color: _lime, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${exercise.name}\n${exercise.sets} séries × ${exercise.reps} · descanso ${exercise.restSeconds}s',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                const Text(
                  'As sugestões são educativas e não substituem avaliação profissional. Ajuste a atividade ao seu condicionamento e interrompa se sentir dor.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        backgroundColor: const Color(0xFF343434),
        side: BorderSide.none,
      );
}
