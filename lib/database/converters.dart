
import '../models/models.dart';
import '../models/workout_plan.dart';
import 'entities.dart';

class Converters {

  static WorkoutEntity workoutToEntity(Workout workout) {
    return WorkoutEntity(
      date: workout.date.toIso8601String(),
    );
  }


  static Workout entityToWorkout(WorkoutEntity entity, List<ExerciseResultEntity> resultEntities) {
    return Workout(
      date: DateTime.parse(entity.date),
      results: resultEntities.map((resultEntity) {
        return ExerciseResult(
          exercise: Exercise(
            name: resultEntity.exerciseName,
            targetOutput: resultEntity.targetOutput,
            unit: _stringToUnit(resultEntity.unitName),
          ),
          achievedOutput: resultEntity.achievedOutput,
        );
      }).toList(),
    );
  }


  static ExerciseResultEntity resultToEntity(ExerciseResult result, int workoutId) {
    return ExerciseResultEntity(
      workoutId: workoutId,
      exerciseName: result.exercise.name,
      targetOutput: result.exercise.targetOutput,
      achievedOutput: result.achievedOutput,
      unitName: result.exercise.unit.name,
    );
  }


  static WorkoutPlanEntity planToEntity(WorkoutPlan plan) {
    return WorkoutPlanEntity(
      name: plan.name,
    );
  }


  static WorkoutPlan entityToPlan(WorkoutPlanEntity entity, List<ExerciseEntity> exerciseEntities) {
    return WorkoutPlan(
      name: entity.name,
      exercises: exerciseEntities.map((exerciseEntity) {
        return Exercise(
          name: exerciseEntity.name,
          targetOutput: exerciseEntity.targetOutput,
          unit: _stringToUnit(exerciseEntity.unitName),
        );
      }).toList(),
    );
  }


  static ExerciseEntity exerciseToEntity(Exercise exercise, int planId) {
    return ExerciseEntity(
      planId: planId,
      name: exercise.name,
      targetOutput: exercise.targetOutput,
      unitName: exercise.unit.name,
    );
  }

  static MeasurementUnit _stringToUnit(String unitName) {
    switch (unitName) {
      case 'seconds':
        return MeasurementUnit.seconds;
      case 'repetitions':
        return MeasurementUnit.repetitions;
      case 'meters':
        return MeasurementUnit.meters;
      default:
        return MeasurementUnit.repetitions;
    }
  }
}