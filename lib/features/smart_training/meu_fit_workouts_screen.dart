import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wger/features/exercises/screens/exercise_screen.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';
import 'package:wger/features/smart_training/meu_fit_exercise_matcher.dart';
import 'package:wger/features/smart_training/starter_workout_planner.dart';

/// Treinos do Meu Fit: semana > dia > exercício.
class MeuFitWorkoutsScreen extends ConsumerWidget {
  const MeuFitWorkoutsScreen({super.key});

  static const _lime = Color(0xFFC9F31D);
  static const _background = Color(0xFF101010);
  static const _surface = Color(0xFF202020);

  static const _weekdays = <String>[
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static const _weekdaySchedules = <int, List<int>>{
    1: [0],
    2: [0, 3],
    3: [0, 2, 4],
    4: [0, 1, 3, 4],
    5: [0, 1, 2, 3, 4],
    6: [0, 1, 2, 3, 4, 5],
    7: [0, 1, 2, 3, 4, 5, 6],
  };

  TrainingProfile _trainingProfile(MeuFitOnboardingProfile profile) {
    return TrainingProfile(
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileFuture = MeuFitOnboardingStorage().load();
    final catalog = ref.watch(exercisesProvider);

    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.dark(primary: _lime, surface: _surface),
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Meus treinos')),
        body: FutureBuilder<MeuFitOnboardingProfile?>(
          future: profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: _lime));
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Não foi possível carregar seu perfil. Complete o cadastro para ver seu plano.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final profile = snapshot.data!;
            if (profile.age < 18 || profile.age > 64 || profile.hasPhysicalLimitations) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  Icon(Icons.health_and_safety_outlined, color: Colors.orangeAccent, size: 44),
                  SizedBox(height: 14),
                  Text(
                    'Seu treino precisa de avaliação individual',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Pelas informações do perfil, procure um profissional de Educação Física para adaptar os exercícios com segurança. Não geramos uma rotina automática para este perfil.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              );
            }

            final plan = const StarterWorkoutPlanner().generate(_trainingProfile(profile));
            final schedule = _weekdaySchedules[profile.daysPerWeek] ?? List<int>.generate(profile.daysPerWeek, (i) => i);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF303A13), Color(0xFF1D1D1D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _lime.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUA SEMANA',
                        style: TextStyle(color: _lime, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${profile.daysPerWeek} ${profile.daysPerWeek == 1 ? 'dia disponível' : 'dias disponíveis'} por semana',
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.trainingLocation == 'casa' ? 'Treinos em casa' : 'Treinos na academia',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('ESCOLHA O DIA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 10),
                for (var i = 0; i < plan.length; i++)
                  _WorkoutWeekdayCard(
                    weekday: _weekdays[schedule[i]],
                    workout: plan[i],
                    onTap: () {
                      final matches = catalog.value == null
                          ? <MeuFitExerciseMatch>[]
                          : const MeuFitExerciseMatcher().match(
                              plan[i].exercises,
                              catalog.value!.exercises,
                            );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MeuFitWorkoutDayScreen(
                            weekday: _weekdays[schedule[i]],
                            workout: plan[i],
                            matches: matches,
                            catalogLoading: catalog.value == null && !catalog.hasError,
                            catalogError: catalog.hasError,
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Toque em um dia para ver todos os exercícios. Abra um exercício para consultar a descrição, as imagens, os músculos trabalhados e os vídeos disponíveis no catálogo.',
                  style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorkoutWeekdayCard extends StatelessWidget {
  const _WorkoutWeekdayCard({
    required this.weekday,
    required this.workout,
    required this.onTap,
  });

  final String weekday;
  final PlannedWorkout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    final count = workout.exercises.length;
    final recovery = count == 0;
    return Card(
      color: const Color(0xFF202020),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: recovery ? const Color(0xFF333333) : lime,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  recovery ? Icons.hotel_outlined : Icons.fitness_center,
                  color: recovery ? Colors.white70 : Colors.black,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(weekday, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      recovery ? 'Recuperação / descanso' : workout.title.replaceFirst(RegExp(r'^Dia \d+ · '), ''),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recovery ? 'Dia de descanso' : '$count exercícios',
                      style: const TextStyle(color: lime, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white60),
            ],
          ),
        ),
      ),
    );
  }
}

class MeuFitWorkoutDayScreen extends StatelessWidget {
  const MeuFitWorkoutDayScreen({
    super.key,
    required this.weekday,
    required this.workout,
    required this.matches,
    required this.catalogLoading,
    required this.catalogError,
  });

  final String weekday;
  final PlannedWorkout workout;
  final List<MeuFitExerciseMatch> matches;
  final bool catalogLoading;
  final bool catalogError;

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF101010),
        colorScheme: const ColorScheme.dark(primary: lime),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101010), foregroundColor: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(weekday)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(workout.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              '${workout.exercises.length} exercícios no dia',
              style: const TextStyle(color: lime, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (workout.exercises.isEmpty)
              const Card(
                color: Color(0xFF202020),
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Hoje é dia de recuperação. Descanse e retome a rotina no próximo dia programado.', style: TextStyle(color: Colors.white70, height: 1.5)),
                ),
              )
            else if (catalogLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: lime)))
            else if (catalogError)
              const Text('Não foi possível carregar o catálogo de exercícios. Tente novamente quando houver conexão.', style: TextStyle(color: Colors.white70))
            else
              for (final match in matches)
                Card(
                  color: const Color(0xFF202020),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    leading: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: lime.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(13)),
                      child: const Icon(Icons.fitness_center, color: lime),
                    ),
                    title: Text(match.planned.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${match.planned.sets} séries × ${match.planned.reps}\nDescanso: ${match.planned.restSeconds} segundos'
                        '${match.found ? '' : '\nDetalhes visuais ainda não disponíveis para este exercício.'}',
                        style: const TextStyle(color: Colors.white70, height: 1.45),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Icon(match.found ? Icons.play_circle_outline : Icons.info_outline, color: lime),
                    onTap: () {
                      final exercise = match.exercise;
                      if (exercise == null) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MeuFitExerciseFallbackScreen(
                              exerciseName: match.planned.name,
                              sets: match.planned.sets,
                              reps: match.planned.reps,
                              restSeconds: match.planned.restSeconds,
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pushNamed(
                        ExerciseDetailScreen.routeName,
                        arguments: exercise,
                      );
                    },
                  ),
                ),
            const SizedBox(height: 12),
            const Text(
              'Faça os movimentos com controle, respeite seus limites e interrompa qualquer exercício que cause dor. Esta rotina é uma sugestão inicial.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}


/// Alternativa transparente quando o catálogo não tem mídia cadastrada para um exercício.
class MeuFitExerciseFallbackScreen extends StatelessWidget {
  const MeuFitExerciseFallbackScreen({
    super.key,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  final String exerciseName;
  final int sets;
  final String reps;
  final int restSeconds;

  String get _muscleGroup {
    final name = exerciseName.toLowerCase();
    if (name.contains('supino') || name.contains('flexão')) return 'peitoral, tríceps e ombros';
    if (name.contains('remada')) return 'costas e bíceps';
    if (name.contains('desenvolvimento')) return 'ombros e tríceps';
    if (name.contains('pélvica') || name.contains('glúteos')) return 'glúteos e músculos do quadril';
    if (name.contains('flexora')) return 'posteriores da coxa';
    if (name.contains('leg press') || name.contains('agachamento')) return 'quadríceps e glúteos';
    if (name.contains('prancha') || name.contains('bird dog')) return 'abdômen e músculos estabilizadores do tronco';
    if (name.contains('terra')) return 'glúteos, posteriores da coxa e costas';
    if (name.contains('alongamento') || name.contains('mobilidade')) return 'músculos e articulações envolvidos no movimento';
    return 'consulte a demonstração e confirme a musculatura com um profissional';
  }

  Future<void> _openSearch(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o navegador neste aparelho.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    final videoUri = Uri.https('www.youtube.com', '/results', {
      'search_query': '$exerciseName execução correta exercício tutorial',
    });
    final imageUri = Uri.https('www.google.com', '/search', {
      'tbm': 'isch',
      'q': 'anatomia músculos $_muscleGroup exercício $exerciseName',
    });

    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF101010),
        colorScheme: const ColorScheme.dark(primary: lime),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101010), foregroundColor: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(exerciseName)),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFF202020), borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SEU EXERCÍCIO', style: TextStyle(color: lime, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 10),
                Text(exerciseName, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text('$sets séries × $reps', style: const TextStyle(color: Colors.white70)),
                Text('Descanso: $restSeconds segundos', style: const TextStyle(color: Colors.white54)),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('MÚSCULOS TRABALHADOS (ESTIMATIVA)', style: TextStyle(color: lime, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(_muscleGroup, style: const TextStyle(fontSize: 17, height: 1.45)),
            const SizedBox(height: 8),
            const Text(
              'O catálogo ainda não possui uma ficha completa para este exercício. Use as pesquisas abaixo para ver imagens anatômicas e uma demonstração; confirme a técnica e os músculos-alvo com um profissional.',
              style: TextStyle(color: Colors.white60, height: 1.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _openSearch(context, imageUri),
              icon: const Icon(Icons.image_search_outlined),
              label: const Text('Ver imagens dos músculos na internet'),
              style: OutlinedButton.styleFrom(foregroundColor: lime, side: const BorderSide(color: lime), padding: const EdgeInsets.all(15)),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _openSearch(context, videoUri),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Ver vídeo da execução'),
              style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: Colors.black, padding: const EdgeInsets.all(15)),
            ),
          ],
        ),
      ),
    );
  }
}
