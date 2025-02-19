import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workoutapp/database/database.dart';
import 'package:workoutapp/database/entities.dart';
import 'package:workoutapp/models/models.dart';
import 'package:workoutapp/models/workout_plan.dart';
import 'package:workoutapp/state/workout_state.dart';
import 'package:workoutapp/pages/workout_recording_page.dart';
import 'package:workoutapp/pages/workout_history_page.dart';
import 'package:workoutapp/pages/workout_details.dart';
import 'package:workoutapp/widgets/exercise_inputs.dart';
import 'package:workoutapp/widgets/recent_performance_widget.dart';
import 'package:intl/intl.dart';

void main() {
  late AppDatabase database;
  late WorkoutState workoutState;
  late WorkoutPlan testPlan;

  setUp(() async {

    database = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();


    testPlan = WorkoutPlan(
      name: 'Test Plan',
      exercises: [
        Exercise(name: 'Push-ups', targetOutput: 20, unit: MeasurementUnit.repetitions),
        Exercise(name: 'Plank', targetOutput: 60, unit: MeasurementUnit.seconds),
        Exercise(name: 'Running', targetOutput: 1000, unit: MeasurementUnit.meters),
      ],
    );

    workoutState = WorkoutState(defaultPlan: testPlan, database: database);
  });

  group('WorkoutRecordingPage Tests', () {
    testWidgets('Shows correct input widgets for each exercise', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: workoutState,
            child: WorkoutRecordingPage(workoutPlan: testPlan),
          ),
        ),
      );

      expect(find.text('Push-ups'), findsOneWidget);
      expect(find.text('Plank'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.byType(RepCounter), findsOneWidget);
      expect(find.byType(TimerInput), findsOneWidget);
      expect(find.byType(DistanceInput), findsOneWidget);
    });
  });



}
