/// Rule-based starter plan generator. No AI or network dependency.
/// The generated plan is a suggestion, not a clinical prescription.
enum FitnessGoal { loseWeight, buildMuscle, stayFit, flexibility }
enum TrainingExperience { beginner, intermediate, advanced }
enum TrainingLocation { gym, home }

class TrainingProfile {
  const TrainingProfile({
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.daysPerWeek,
    required this.goal,
    required this.experience,
    required this.location,
    this.avoidKneeImpact = false,
  });

  final int age;
  final double weightKg;
  final double heightCm;
  final int daysPerWeek;
  final FitnessGoal goal;
  final TrainingExperience experience;
  final TrainingLocation location;
  final bool avoidKneeImpact;
}

class PlannedExercise {
  const PlannedExercise(this.name, this.sets, this.reps, this.restSeconds);
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
}

class PlannedWorkout {
  const PlannedWorkout(this.title, this.exercises);
  final String title;
  final List<PlannedExercise> exercises;
}

class StarterWorkoutPlanner {
  const StarterWorkoutPlanner();

  List<PlannedWorkout> generate(TrainingProfile profile) {
    if (profile.age < 18 || profile.age > 64 || profile.avoidKneeImpact ||
        !profile.weightKg.isFinite || profile.weightKg <= 0 ||
        !profile.heightCm.isFinite || profile.heightCm <= 0 ||
        profile.daysPerWeek < 1 || profile.daysPerWeek > 7) {
      throw ArgumentError('Perfil de treino inválido');
    }

    // Protocolo educativo inicial de mobilidade, ainda sujeito a revisão profissional.
    // Evita sobrepor alongamento com o programa resistido.
    if (profile.goal == FitnessGoal.flexibility) {
      const mobility = <PlannedExercise>[
        PlannedExercise('Mobilidade de ombros', 1, '5–8 movimentos suaves', 30),
        PlannedExercise('Mobilidade torácica', 1, '5–8 movimentos por lado', 30),
        PlannedExercise('Alongamento de panturrilhas', 1, '15–30 segundos por lado', 30),
        PlannedExercise('Alongamento de peitoral', 1, '15–30 segundos', 30),
      ];
      return List.generate(
        profile.daysPerWeek,
        (day) => PlannedWorkout('Dia ${day + 1} · Mobilidade e flexibilidade', mobility),
      );
    }

    final sets = switch (profile.experience) {
      TrainingExperience.beginner => 2,
      TrainingExperience.intermediate => 3,
      TrainingExperience.advanced => 4,
    };
    final rest = profile.goal == FitnessGoal.buildMuscle ? 90 : 60;
    PlannedExercise exercise(String name, [String reps = '8–12']) =>
        PlannedExercise(name, sets, reps, rest);

    final home = profile.location == TrainingLocation.home;
    final upper = [
      exercise(home ? 'Flexão inclinada' : 'Supino na máquina'),
      exercise(home ? 'Remada com elástico' : 'Remada sentada'),
      exercise(home ? 'Desenvolvimento com elástico' : 'Desenvolvimento na máquina'),
    ];
    final lower = [
      exercise(home ? 'Ponte de glúteos' : 'Elevação pélvica'),
      exercise(home ? 'Levantamento terra com mochila' : 'Mesa flexora'),
      if (!profile.avoidKneeImpact)
        exercise(home ? 'Agachamento até uma cadeira' : 'Leg press'),
    ];
    final core = [
      exercise('Prancha', '20–30 segundos'),
      exercise('Extensão alternada de braço e perna', '8–10 por lado'),
    ];
    final full = [...upper.take(2), ...lower.take(2), ...core.take(1)];
    final split = profile.daysPerWeek <= 3
        ? [PlannedWorkout('Corpo inteiro', full)]
        : [
            PlannedWorkout('Parte superior', upper),
            PlannedWorkout('Parte inferior', [...lower, ...core]),
          ];

    // A quantidade informada representa disponibilidade, não obrigação de
    // repetir musculação diariamente. Reservar dias adicionais para descanso
    // ou atividade leve até que a programação semanal seja validada.
    final activeDays = profile.daysPerWeek <= 4
        ? List<int>.generate(profile.daysPerWeek, (i) => i)
        : profile.daysPerWeek == 5
            ? <int>[0, 1, 3, 4]
            : <int>[0, 2, 4, 6].where((day) => day < profile.daysPerWeek).toList();
    return List.generate(profile.daysPerWeek, (day) {
      final sessionIndex = activeDays.indexOf(day);
      if (sessionIndex == -1) {
        return PlannedWorkout('Dia ${day + 1} · Recuperação', const []);
      }
      final template = split[sessionIndex % split.length];
      return PlannedWorkout('Dia ${day + 1} · ${template.title}', template.exercises);
    });
  }
}
