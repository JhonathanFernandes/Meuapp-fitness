import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Dados informados pelo usuário no primeiro acesso do Meu Fit.
/// A persistência é local nesta etapa; sincronização virá depois.
class MeuFitOnboardingProfile {
  const MeuFitOnboardingProfile({
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.experience,
    required this.daysPerWeek,
    required this.trainingLocation,
    required this.hasPhysicalLimitations,
    this.limitationsDescription = '',
  });

  final int age;
  final double weightKg;
  final double heightCm;
  final String goal;
  final String experience;
  final int daysPerWeek;
  final String trainingLocation;
  final bool hasPhysicalLimitations;
  final String limitationsDescription;

  static const goals = ['emagrecer', 'ganhar_massa', 'manter_forma'];
  static const experiences = ['iniciante', 'intermediario', 'avancado'];
  static const locations = ['academia', 'casa'];

  void validate() {
    if (age < 13 || age > 100 ||
        !weightKg.isFinite || weightKg < 20 || weightKg > 500 ||
        !heightCm.isFinite || heightCm < 100 || heightCm > 250 ||
        daysPerWeek < 1 || daysPerWeek > 7 ||
        !goals.contains(goal) || !experiences.contains(experience) ||
        !locations.contains(trainingLocation)) {
      throw const FormatException('Confira as informações preenchidas.');
    }
  }

  Map<String, dynamic> toJson() => {
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'goal': goal,
    'experience': experience,
    'daysPerWeek': daysPerWeek,
    'trainingLocation': trainingLocation,
    'hasPhysicalLimitations': hasPhysicalLimitations,
    'limitationsDescription': limitationsDescription,
  };

  factory MeuFitOnboardingProfile.fromJson(Map<String, dynamic> json) {
    final profile = MeuFitOnboardingProfile(
      age: (json['age'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      goal: json['goal'] as String,
      experience: json['experience'] as String,
      daysPerWeek: (json['daysPerWeek'] as num).toInt(),
      trainingLocation: json['trainingLocation'] as String,
      hasPhysicalLimitations: json['hasPhysicalLimitations'] as bool,
      limitationsDescription: json['limitationsDescription'] as String? ?? '',
    );
    profile.validate();
    return profile;
  }
}

class MeuFitOnboardingStorage {
  static const _key = 'meu_fit_onboarding_v1';

  Future<void> save(MeuFitOnboardingProfile profile) async {
    profile.validate();
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_key, jsonEncode(profile.toJson()));
    if (!saved) throw StateError('Não foi possível salvar as respostas.');
  }

  Future<MeuFitOnboardingProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    return MeuFitOnboardingProfile.fromJson(
      jsonDecode(data) as Map<String, dynamic>,
    );
  }
}
