/// Rule-based starter plan generator. No AI or network dependency.
/// The generated plan is a suggestion, not a clinical prescription.
enum FitnessGoal { loseWeight, buildMuscle, stayFit }
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
    if (profile.age < 13 || profile.age > 100 ||
        !profile.weightKg.isFinite || profile.weightKg <= 0 ||
        !profile.heightCm.isFinite || profile.heightCm <= 0 ||
        profile.daysPerWeek < 1 || profile.daysPerWeek > 7) {
      throw ArgumentError('Perfil de treino inválido');
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
      exercise('Bird dog', '8–10 por lado'),
    ];
    final full = [...upper.take(2), ...lower.take(2), ...core.take(1)];
    final split = profile.daysPerWeek <= 3
        ? [PlannedWorkout('Corpo inteiro', full)]
        : [
            PlannedWorkout('Parte superior', upper),
            PlannedWorkout('Parte inferior', [...lower, ...core]),
          ];

    return List.generate(profile.daysPerWeek, (day) {
      final template = split[day % split.length];
      return PlannedWorkout('Dia ${day + 1} · ${template.title}', template.exercises);
    });
  }
}
