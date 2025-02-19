
import 'package:floor/floor.dart';
import 'entities.dart';

@dao
abstract class WorkoutDao {
  @Query('SELECT * FROM WorkoutEntity')
  Future<List<WorkoutEntity>> findAllWorkouts();

  @insert
  Future<int> insertWorkout(WorkoutEntity workout);

  @delete
  Future<void> deleteWorkout(WorkoutEntity workout);
}

@dao
abstract class ExerciseResultDao {
  @Query('SELECT * FROM ExerciseResultEntity WHERE workoutId = :workoutId')
  Future<List<ExerciseResultEntity>> findResultsForWorkout(int workoutId);

  @insert
  Future<void> insertResult(ExerciseResultEntity result);

  @delete
  Future<void> deleteResult(ExerciseResultEntity result);
}

@dao
abstract class WorkoutPlanDao {
  @Query('SELECT * FROM WorkoutPlanEntity')
  Future<List<WorkoutPlanEntity>> findAllPlans();

  @insert
  Future<int> insertPlan(WorkoutPlanEntity plan);

  @delete
  Future<void> deletePlan(WorkoutPlanEntity plan);
}

@dao
abstract class ExerciseDao {
  @Query('SELECT * FROM ExerciseEntity WHERE planId = :planId')
  Future<List<ExerciseEntity>> findExercisesForPlan(int planId);

  @insert
  Future<void> insertExercise(ExerciseEntity exercise);

  @delete
  Future<void> deleteExercise(ExerciseEntity exercise);
}