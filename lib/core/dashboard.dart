import 'package:flutter/material.dart';
import 'package:wger/features/onboarding/meu_fit_onboarding_profile.dart';
import 'package:wger/features/smart_training/starter_workout_planner.dart';
import 'package:wger/features/smart_training/meu_fit_workouts_screen.dart';

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
  static const _surface = Color(0xFF1D1D1D);

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
  Widget build(BuildContext context) => Theme(
    data: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: _background,
      colorScheme: const ColorScheme.dark(primary: _lime, surface: _surface),
      appBarTheme: const AppBarTheme(backgroundColor: _background, foregroundColor: Colors.white, elevation: 0),
    ),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('MEU FIT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.8)),
        actions: const [Padding(padding: EdgeInsets.only(right: 18), child: Icon(Icons.notifications_none_rounded, color: _lime))],
      ),
      body: FutureBuilder<MeuFitOnboardingProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _lime));
          }
          if (snapshot.hasError) {
            return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Não foi possível carregar seu perfil. Tente abrir o aplicativo novamente.')));
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Seu perfil ainda não foi preenchido. Volte ao início para configurar seus objetivos.')));
          }

          final needsReview = profile.age < 18 || profile.age > 64 || profile.hasPhysicalLimitations;
          final plan = needsReview ? const <PlannedWorkout>[] : const StarterWorkoutPlanner().generate(
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
              location: profile.trainingLocation == 'casa' ? TrainingLocation.home : TrainingLocation.gym,
              avoidKneeImpact: profile.hasPhysicalLimitations,
            ),
          );
          final totalExercises = plan.fold<int>(0, (sum, day) => sum + day.exercises.length);

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              const Text('BORA EVOLUIR?', style: TextStyle(color: _lime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 5),
              const Text('Olá, atleta 👋', style: TextStyle(fontSize: 29, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
              const SizedBox(height: 7),
              const Text('Seu próximo nível começa hoje.', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF303A13), Color(0xFF1C2114), Color(0xFF1B1B1B)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _lime.withValues(alpha: 0.55)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(9)),
                      child: const Text('SEU OBJETIVO', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
                    const Spacer(),
                    const Icon(Icons.bolt_rounded, color: _lime, size: 28),
                  ]),
                  const SizedBox(height: 18),
                  Text(_goalLabel(profile.goal), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 8),
                  Text(profile.daysPerWeek.toString() + ' dias por semana  •  ' + _experienceLabel(profile.experience), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 18),
                  const Row(children: [
                    Icon(Icons.check_circle_rounded, color: _lime, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Plano montado para o seu perfil', style: TextStyle(color: Colors.white70, fontSize: 12))),
                  ]),
                ]),
              ),
              const SizedBox(height: 23),
              const _SectionHeading(title: 'SEU RESUMO', subtitle: 'Seu ponto de partida'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _MetricCard(icon: Icons.monitor_weight_outlined, label: 'PESO ATUAL', value: profile.weightKg.toStringAsFixed(1), unit: 'kg')),
                const SizedBox(width: 10),
                Expanded(child: _MetricCard(icon: Icons.height_rounded, label: 'ALTURA', value: profile.heightCm.toStringAsFixed(0), unit: 'cm')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _MetricCard(icon: Icons.calendar_month_rounded, label: 'ROTINA', value: profile.daysPerWeek.toString(), unit: 'dias/semana')),
                const SizedBox(width: 10),
                Expanded(child: _MetricCard(icon: Icons.fitness_center_rounded, label: 'EXERCÍCIOS', value: totalExercises.toString(), unit: 'no plano')),
              ]),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Expanded(child: _SectionHeading(title: 'PLANO DE TREINO', subtitle: 'Preparado para seu perfil')),
                if (plan.isNotEmpty) Text(plan.length.toString() + ' dias', style: const TextStyle(color: _lime, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              if (needsReview)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.35))),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.health_and_safety_outlined, color: Colors.orangeAccent),
                    SizedBox(width: 12),
                    Expanded(child: Text('Pelo perfil informado, é necessária uma avaliação individual com profissional de Educação Física antes de apresentar um treino automático personalizado.', style: TextStyle(color: Colors.white70, height: 1.4))),
                  ]),
                )
              else if (plan.isEmpty)
                const Text('Não foi possível gerar sugestões para este perfil no momento.')
              else
                for (var i = 0; i < plan.length; i++) _WorkoutDayCard(dayNumber: i + 1, workout: plan[i]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFF191919), borderRadius: BorderRadius.circular(16)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, color: _lime, size: 19),
                  SizedBox(width: 10),
                  Expanded(child: Text('Este plano é uma sugestão inicial e não substitui orientação profissional. Respeite seus limites e interrompa qualquer exercício que cause dor.', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.45))),
                ]),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
    const SizedBox(height: 4),
    Text(subtitle, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
  ]);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.unit});
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xFF1D1D1D), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFFC9F31D), size: 21),
      const SizedBox(height: 15),
      Text(label, style: const TextStyle(color: Color(0xFF858585), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
      const SizedBox(height: 5),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, height: 1))),
        const SizedBox(width: 4),
        Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(unit, style: const TextStyle(color: Color(0xFF999999), fontSize: 10))),
      ]),
    ]),
  );
}

class _WorkoutDayCard extends StatelessWidget {
  const _WorkoutDayCard({required this.dayNumber, required this.workout});
  final int dayNumber;
  final PlannedWorkout workout;
  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9F31D);
    final count = workout.exercises.length;
    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MeuFitWorkoutsScreen())),
      child: Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1D1D1D), borderRadius: BorderRadius.circular(19), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 45, height: 45, alignment: Alignment.center, decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(14)),
            child: Text(dayNumber.toString(), style: const TextStyle(color: Colors.black, fontSize: 21, fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DIA ' + dayNumber.toString(), style: const TextStyle(color: lime, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(workout.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 15),
        ]),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF292929), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fitness_center_rounded, size: 14, color: lime),
            const SizedBox(width: 7),
            Text(count.toString() + ' exercícios', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
        const SizedBox(height: 12),
        for (final exercise in workout.exercises.take(3))
          Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [
            Container(width: 5, height: 5, decoration: const BoxDecoration(color: lime, shape: BoxShape.circle)),
            const SizedBox(width: 9),
            Expanded(child: Text(exercise.name, style: const TextStyle(color: Colors.white70, fontSize: 12))),
            Text(exercise.sets.toString() + ' × ' + exercise.reps.toString(), style: const TextStyle(color: Color(0xFF9B9B9B), fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
        if (count > 3) Padding(padding: const EdgeInsets.only(top: 2), child: Text('+ ' + (count - 3).toString() + ' exercícios', style: const TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
      ),
    );
  }
}
