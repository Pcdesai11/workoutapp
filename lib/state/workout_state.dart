import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/workout_plan.dart';
import '../database/database.dart';
import '../database/entities.dart';
import '../database/converters.dart';

class WorkoutState extends ChangeNotifier {
  final AppDatabase database;
  final WorkoutPlan defaultPlan;
  List<Workout> _workouts = [];
  List<WorkoutPlan> _plans = [];

  WorkoutState({required this.database, required this.defaultPlan});

  List<Workout> get workouts => List.unmodifiable(_workouts);
  List<WorkoutPlan> get availablePlans => [defaultPlan, ..._plans];

  Future<void> loadWorkouts() async {
    final workoutEntities = await database.workoutDao.findAllWorkouts();
    _workouts = [];

    for (var entity in workoutEntities) {
      final results = await database.exerciseResultDao.findResultsForWorkout(entity.id!);
      _workouts.add(Converters.entityToWorkout(entity, results));
    }

    notifyListeners();
  }

  Future<void> loadPlans() async {
    final planEntities = await database.workoutPlanDao.findAllPlans();
    _plans = [];

    for (var entity in planEntities) {
      final exercises = await database.exerciseDao.findExercisesForPlan(entity.id!);
      _plans.add(Converters.entityToPlan(entity, exercises));
    }

    notifyListeners();
  }

  Future<void> addWorkout(Workout workout) async {

    final workoutEntity = Converters.workoutToEntity(workout);
    final workoutId = await database.workoutDao.insertWorkout(workoutEntity);


    for (var result in workout.results) {
      final resultEntity = Converters.resultToEntity(result, workoutId);
      await database.exerciseResultDao.insertResult(resultEntity);
    }

    await loadWorkouts();
  }

  Future<void> savePlan(WorkoutPlan plan) async {

    final planEntity = Converters.planToEntity(plan);
    final planId = await database.workoutPlanDao.insertPlan(planEntity);


    for (var exercise in plan.exercises) {
      final exerciseEntity = Converters.exerciseToEntity(exercise, planId);
      await database.exerciseDao.insertExercise(exerciseEntity);
    }

    await loadPlans();
  }

  double getRecentPerformanceScore() {
    final now = DateTime.now();
    final lastWeekWorkouts = _workouts.where((workout) {
      final difference = now.difference(workout.date).inDays;
      return difference <= 7;
    }).toList();

    if (lastWeekWorkouts.isEmpty) return 0;

    int totalExercises = 0;
    int successfulExercises = 0;

    for (var workout in lastWeekWorkouts) {
      totalExercises += workout.results.length;
      successfulExercises += workout.results
          .where((result) => result.isSuccessful)
          .length;
    }

    return (successfulExercises / totalExercises) * 100;
  }
}