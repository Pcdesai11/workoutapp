import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'entities.dart';
import 'daos.dart';

part 'database.g.dart';

@Database(version: 1, entities: [WorkoutEntity, ExerciseResultEntity, WorkoutPlanEntity, ExerciseEntity])
abstract class AppDatabase extends FloorDatabase {
  WorkoutDao get workoutDao;
  ExerciseResultDao get exerciseResultDao;
  WorkoutPlanDao get workoutPlanDao;
  ExerciseDao get exerciseDao;

  static Future<AppDatabase> buildDatabase() async {
    return await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  }
}