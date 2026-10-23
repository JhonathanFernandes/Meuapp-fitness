import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/smart_training/meu_fit_exercise_matcher.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';
import 'package:wger/features/smart_training/starter_workout_planner.dart';
import 'package:wger/features/smart_training/meu_fit_saved_plan.dart';

/// Prévia de treino sugerido com base nas respostas do cadastro.
/// Nesta etapa, não cria nem altera rotinas existentes no servidor wger.
class MeuFitPlanScreen extends ConsumerWidget {
  const MeuFitPlanScreen({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  final MeuFitOnboardingProfile profile;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requiresIndividualReview = profile.age < 18 || profile.age > 64 ||
        profile.hasPhysicalLimitations;
    final plan = requiresIndividualReview ? const <PlannedWorkout>[] :
        const StarterWorkoutPlanner().generate(
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

    final goalExplanation = switch (profile.goal) {
      'emagrecer' => 'Objetivo: emagrecimento. A atividade física regular pode '
          'ajudar no gasto energético e na saúde cardiometabólica. O treino '
          'de força complementa o trabalho aeróbico; a perda de peso '
          'não depende apenas dos exercícios.',
      'ganhar_massa' => 'Objetivo: hipertrofia. O treinamento resistido '
          'precisa de progressão, recuperação e volume adequados. '
          'As séries apresentadas são apenas uma referência inicial.',
      'flexibilidade' => 'Objetivo: flexibilidade. A sessão prioriza '
          'mobilidade e alongamentos suaves, sem forçar amplitude '
          'ou usar dor como sinal de progresso.',
      _ => 'Objetivo: condicionamento e manutenção. A prática regular '
          'pode combinar fortalecimento e atividade aeróbica, '
          'com progressão gradual.',
    };
    final evidenceSource = switch (profile.goal) {
      'ganhar_massa' => 'Referência: ACSM, atualização sobre treinamento '
          'resistido (2026).',
      'flexibilidade' => 'Referência: ACSM, diretrizes gerais de '
          'flexibilidade e aptidão física.',
      _ => 'Referência: Ministério da Saúde, Guia de Atividade Física '
          'para a População Brasileira (2021).',
    };

    final catalog = ref.watch(exercisesProvider);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('POR QUE ESTE TIPO DE TREINO?',
                          style: TextStyle(
                              color: lime, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(goalExplanation),
                      const SizedBox(height: 8),
                      Text(evidenceSource,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              if (requiresIndividualReview)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    'Seu perfil indica que é necessária uma avaliação individual '
                    'com profissional de Educação Física antes de seguir um treino '
                    'personalizado. Nenhuma rotina será criada automaticamente.',
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Sugestão educativa baseada em diretrizes de atividade física. '
                  'Não é prescrição profissional nem garante resultados.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
              Expanded(
                child: requiresIndividualReview
                    ? const Center(child: Text('Treino automático indisponível para este perfil.'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: plan.length,
                  itemBuilder: (context, index) {
                    final day = plan[index];
                    final matches = catalog.value == null
                        ? null
                        : const MeuFitExerciseMatcher().match(
                            day.exercises, catalog.value!.exercises);
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
                            if (matches == null)
                              const Text('Carregando biblioteca de exercícios...'),
                            if (matches != null)
                              for (final match in matches)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• ${match.planned.name} · ${match.planned.sets} séries '
                                  '× ${match.planned.reps} · descanso ${match.planned.restSeconds}s · '
                                  '${match.found ? "✓ Encontrado no catálogo" : "⚠ Não encontrado no catálogo"}',
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!requiresIndividualReview)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await MeuFitSavedPlan().save(plan);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(
                              'Plano salvo neste celular. Ainda não foi adicionado às rotinas.',
                            )),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(
                              'Não foi possível salvar o plano.',
                            )),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar plano neste celular'),
                    ),
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
