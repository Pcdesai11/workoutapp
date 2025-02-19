enum MeasurementUnit { seconds, repetitions, meters }

class Exercise {
  final String name;
  final double targetOutput;
  final MeasurementUnit unit;

  Exercise({required this.name, required this.targetOutput, required this.unit});
}

class ExerciseResult {
  final Exercise exercise;
  final double achievedOutput;

  ExerciseResult({required this.exercise, required this.achievedOutput});

  bool get isSuccessful => achievedOutput >= exercise.targetOutput;
}

class Workout {
  final DateTime date;
  final List<ExerciseResult> results;

  Workout({required this.date, required this.results});
}
