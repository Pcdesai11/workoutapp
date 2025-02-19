import 'models.dart';
import 'workout_plan.dart';

final mockWorkoutPlan = WorkoutPlan(
  name: 'Full Body Workout',
  exercises: [
    Exercise(
      name: 'Push-ups',
      targetOutput: 20,
      unit: MeasurementUnit.repetitions,
    ),
    Exercise(
      name: 'Plank',
      targetOutput: 60,
      unit: MeasurementUnit.seconds,
    ),
    Exercise(
      name: 'Running',
      targetOutput: 1000,
      unit: MeasurementUnit.meters,
    ),
    Exercise(
      name: 'Hill climbing',
      targetOutput: 800,
      unit: MeasurementUnit.meters,
    ),
    Exercise(
      name: 'Step-climbing',
      targetOutput:50,
      unit: MeasurementUnit.repetitions,
    ),
    Exercise(
      name: 'Squats',
      targetOutput: 15,
      unit: MeasurementUnit.repetitions,
    ),
    Exercise(
      name: 'Rope Skipping',
      targetOutput: 120,
      unit: MeasurementUnit.seconds,
    ),

  ],
);