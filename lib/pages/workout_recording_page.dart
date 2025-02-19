import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/workout_plan.dart';
import '../state/workout_state.dart';
import '../widgets/exercise_inputs.dart';

class WorkoutRecordingPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const WorkoutRecordingPage({Key? key, required this.workoutPlan})
      : super(key: key);

  @override
  State<WorkoutRecordingPage> createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  final Map<Exercise, double> _results = {};

  Widget _buildInputWidget(Exercise exercise) {
    switch (exercise.name) {
      case 'Plank':
      case 'Rope Skipping':
        return TimerInput(
          onValueChanged: (value) => _updateResult(exercise, value),
          targetValue: exercise.targetOutput,
        );
      case 'Push-ups':
      case 'Squats':
        return RepCounter(
          onValueChanged: (value) => _updateResult(exercise, value),
          targetValue: exercise.targetOutput,
        );
      case 'Running':
      case 'Hill climbing':
        return DistanceInput(
          onValueChanged: (value) => _updateResult(exercise, value),
          targetValue: exercise.targetOutput,
        );
      case 'Step-climbing':
        return StepCounter(
          onValueChanged: (value) => _updateResult(exercise, value),
          targetValue: exercise.targetOutput,
        );
      default:
        return SliderInput(
          onValueChanged: (value) => _updateResult(exercise, value),
          targetValue: exercise.targetOutput,
        );
    }
  }

  void _updateResult(Exercise exercise, double value) {
    setState(() {
      _results[exercise] = value;
    });
  }

  void _finishWorkout() {
    final workout = Workout(
      date: DateTime.now(),
      results: widget.workoutPlan.exercises
          .map((exercise) => ExerciseResult(
        exercise: exercise,
        achievedOutput: _results[exercise] ?? 0,
      ))
          .toList(),
    );

    Provider.of<WorkoutState>(context, listen: false).addWorkout(workout);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutPlan.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.workoutPlan.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.workoutPlan.exercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Target: ${exercise.targetOutput} ${exercise.unit.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildInputWidget(exercise),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _results.length == widget.workoutPlan.exercises.length
                    ? _finishWorkout
                    : null,
                child: const Text('FINISH WORKOUT'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}