// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  WorkoutDao? _workoutDaoInstance;

  ExerciseResultDao? _exerciseResultDaoInstance;

  WorkoutPlanDao? _workoutPlanDaoInstance;

  ExerciseDao? _exerciseDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WorkoutEntity` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `date` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ExerciseResultEntity` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `workoutId` INTEGER NOT NULL, `exerciseName` TEXT NOT NULL, `targetOutput` REAL NOT NULL, `achievedOutput` REAL NOT NULL, `unitName` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WorkoutPlanEntity` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ExerciseEntity` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `planId` INTEGER NOT NULL, `name` TEXT NOT NULL, `targetOutput` REAL NOT NULL, `unitName` TEXT NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  WorkoutDao get workoutDao {
    return _workoutDaoInstance ??= _$WorkoutDao(database, changeListener);
  }

  @override
  ExerciseResultDao get exerciseResultDao {
    return _exerciseResultDaoInstance ??=
        _$ExerciseResultDao(database, changeListener);
  }

  @override
  WorkoutPlanDao get workoutPlanDao {
    return _workoutPlanDaoInstance ??=
        _$WorkoutPlanDao(database, changeListener);
  }

  @override
  ExerciseDao get exerciseDao {
    return _exerciseDaoInstance ??= _$ExerciseDao(database, changeListener);
  }
}

class _$WorkoutDao extends WorkoutDao {
  _$WorkoutDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _workoutEntityInsertionAdapter = InsertionAdapter(
            database,
            'WorkoutEntity',
            (WorkoutEntity item) =>
                <String, Object?>{'id': item.id, 'date': item.date}),
        _workoutEntityDeletionAdapter = DeletionAdapter(
            database,
            'WorkoutEntity',
            ['id'],
            (WorkoutEntity item) =>
                <String, Object?>{'id': item.id, 'date': item.date});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WorkoutEntity> _workoutEntityInsertionAdapter;

  final DeletionAdapter<WorkoutEntity> _workoutEntityDeletionAdapter;

  @override
  Future<List<WorkoutEntity>> findAllWorkouts() async {
    return _queryAdapter.queryList('SELECT * FROM WorkoutEntity',
        mapper: (Map<String, Object?> row) =>
            WorkoutEntity(id: row['id'] as int?, date: row['date'] as String));
  }

  @override
  Future<int> insertWorkout(WorkoutEntity workout) {
    return _workoutEntityInsertionAdapter.insertAndReturnId(
        workout, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteWorkout(WorkoutEntity workout) async {
    await _workoutEntityDeletionAdapter.delete(workout);
  }
}

class _$ExerciseResultDao extends ExerciseResultDao {
  _$ExerciseResultDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _exerciseResultEntityInsertionAdapter = InsertionAdapter(
            database,
            'ExerciseResultEntity',
            (ExerciseResultEntity item) => <String, Object?>{
                  'id': item.id,
                  'workoutId': item.workoutId,
                  'exerciseName': item.exerciseName,
                  'targetOutput': item.targetOutput,
                  'achievedOutput': item.achievedOutput,
                  'unitName': item.unitName
                }),
        _exerciseResultEntityDeletionAdapter = DeletionAdapter(
            database,
            'ExerciseResultEntity',
            ['id'],
            (ExerciseResultEntity item) => <String, Object?>{
                  'id': item.id,
                  'workoutId': item.workoutId,
                  'exerciseName': item.exerciseName,
                  'targetOutput': item.targetOutput,
                  'achievedOutput': item.achievedOutput,
                  'unitName': item.unitName
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ExerciseResultEntity>
      _exerciseResultEntityInsertionAdapter;

  final DeletionAdapter<ExerciseResultEntity>
      _exerciseResultEntityDeletionAdapter;

  @override
  Future<List<ExerciseResultEntity>> findResultsForWorkout(
      int workoutId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ExerciseResultEntity WHERE workoutId = ?1',
        mapper: (Map<String, Object?> row) => ExerciseResultEntity(
            id: row['id'] as int?,
            workoutId: row['workoutId'] as int,
            exerciseName: row['exerciseName'] as String,
            targetOutput: row['targetOutput'] as double,
            achievedOutput: row['achievedOutput'] as double,
            unitName: row['unitName'] as String),
        arguments: [workoutId]);
  }

  @override
  Future<void> insertResult(ExerciseResultEntity result) async {
    await _exerciseResultEntityInsertionAdapter.insert(
        result, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteResult(ExerciseResultEntity result) async {
    await _exerciseResultEntityDeletionAdapter.delete(result);
  }
}

class _$WorkoutPlanDao extends WorkoutPlanDao {
  _$WorkoutPlanDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _workoutPlanEntityInsertionAdapter = InsertionAdapter(
            database,
            'WorkoutPlanEntity',
            (WorkoutPlanEntity item) =>
                <String, Object?>{'id': item.id, 'name': item.name}),
        _workoutPlanEntityDeletionAdapter = DeletionAdapter(
            database,
            'WorkoutPlanEntity',
            ['id'],
            (WorkoutPlanEntity item) =>
                <String, Object?>{'id': item.id, 'name': item.name});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WorkoutPlanEntity> _workoutPlanEntityInsertionAdapter;

  final DeletionAdapter<WorkoutPlanEntity> _workoutPlanEntityDeletionAdapter;

  @override
  Future<List<WorkoutPlanEntity>> findAllPlans() async {
    return _queryAdapter.queryList('SELECT * FROM WorkoutPlanEntity',
        mapper: (Map<String, Object?> row) => WorkoutPlanEntity(
            id: row['id'] as int?, name: row['name'] as String));
  }

  @override
  Future<int> insertPlan(WorkoutPlanEntity plan) {
    return _workoutPlanEntityInsertionAdapter.insertAndReturnId(
        plan, OnConflictStrategy.abort);
  }

  @override
  Future<void> deletePlan(WorkoutPlanEntity plan) async {
    await _workoutPlanEntityDeletionAdapter.delete(plan);
  }
}

class _$ExerciseDao extends ExerciseDao {
  _$ExerciseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _exerciseEntityInsertionAdapter = InsertionAdapter(
            database,
            'ExerciseEntity',
            (ExerciseEntity item) => <String, Object?>{
                  'id': item.id,
                  'planId': item.planId,
                  'name': item.name,
                  'targetOutput': item.targetOutput,
                  'unitName': item.unitName
                }),
        _exerciseEntityDeletionAdapter = DeletionAdapter(
            database,
            'ExerciseEntity',
            ['id'],
            (ExerciseEntity item) => <String, Object?>{
                  'id': item.id,
                  'planId': item.planId,
                  'name': item.name,
                  'targetOutput': item.targetOutput,
                  'unitName': item.unitName
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ExerciseEntity> _exerciseEntityInsertionAdapter;

  final DeletionAdapter<ExerciseEntity> _exerciseEntityDeletionAdapter;

  @override
  Future<List<ExerciseEntity>> findExercisesForPlan(int planId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ExerciseEntity WHERE planId = ?1',
        mapper: (Map<String, Object?> row) => ExerciseEntity(
            id: row['id'] as int?,
            planId: row['planId'] as int,
            name: row['name'] as String,
            targetOutput: row['targetOutput'] as double,
            unitName: row['unitName'] as String),
        arguments: [planId]);
  }

  @override
  Future<void> insertExercise(ExerciseEntity exercise) async {
    await _exerciseEntityInsertionAdapter.insert(
        exercise, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteExercise(ExerciseEntity exercise) async {
    await _exerciseEntityDeletionAdapter.delete(exercise);
  }
}
