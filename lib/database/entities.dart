import 'package:floor/floor.dart';
import '../models/models.dart';

@entity
class WorkoutEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String date;

  WorkoutEntity({this.id, required this.date});
}

@entity
class ExerciseResultEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int workoutId;
  final String exerciseName;
  final double targetOutput;
  final double achievedOutput;
  final String unitName;

  ExerciseResultEntity({
    this.id,
    required this.workoutId,
    required this.exerciseName,
    required this.targetOutput,
    required this.achievedOutput,
    required this.unitName,
  });
}

@entity
class WorkoutPlanEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String name;

  WorkoutPlanEntity({this.id, required this.name});
}

@entity
class ExerciseEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int planId;
  final String name;
  final double targetOutput;
  final String unitName;

  ExerciseEntity({
    this.id,
    required this.planId,
    required this.name,
    required this.targetOutput,
    required this.unitName,
  });
}