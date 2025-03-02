// lib/pages/workout_recording_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../models/workout_plan.dart';
import '../models/group_workout.dart';
import '../state/workout_state.dart';
import '../services/group_workout_services.dart';
import '../widgets/exercise_inputs.dart';

class WorkoutRecordingPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  final String? inviteCode;
  final Stream<Map<String, dynamic>>? groupWorkoutStream;

  const WorkoutRecordingPage({
    Key? key,
    required this.workoutPlan,
    this.inviteCode,
    this.groupWorkoutStream,
  }) : super(key: key);

  @override
  State<WorkoutRecordingPage> createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  final Map<Exercise, double> _results = {};
  final GroupWorkoutService _workoutService = GroupWorkoutService();
  Map<String, dynamic>? _groupResults;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    if (widget.groupWorkoutStream != null) {
      widget.groupWorkoutStream!.listen((results) {
        setState(() {
          _groupResults = results;
        });
      });
    }
  }

  Widget _buildInviteCode() {
    if (widget.inviteCode == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Invite Code',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.inviteCode!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // Copy to clipboard
                    // You'll need to add the flutter_clipboard package
                    // Clipboard.setData(ClipboardData(text: widget.inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: widget.inviteCode!,
              size: 150,
            ),
            if (_groupResults != null) ...[
              const SizedBox(height: 16),
              Text(
                '${(_groupResults!['participants'] as List).length} participants joined',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputWidget(Exercise exercise) {
    // Get real-time results for the exercise if it's a group workout
    String? resultInfo;
    if (_groupResults != null && _groupResults!['isCollaborative']) {
      final results = _groupResults!['results'] as Map<String, dynamic>;
      double total = 0;
      results.forEach((userId, userResults) {
        if (userResults[exercise.name] != null) {
          total += (userResults[exercise.name] as num).toDouble();
        }
      });
      resultInfo = 'Group total: $total ${exercise.unit.name}';
    }

    return Column(
      children: [
        if (resultInfo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(resultInfo),
          ),
        _buildExerciseInput(exercise),
      ],
    );
  }

  Widget _buildExerciseInput(Exercise exercise) {
    // Your existing _buildInputWidget logic here
    // This is the same as your current implementation
    switch (exercise.name) {
      case 'Plank':
      case 'Rope Skipping':
        return TimerInput(
          onValueChanged: (value) => _updateResult(exercise, value),
          targetValue: exercise.targetOutput,
        );
    // ... rest of your cases
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

  Future<void> _finishWorkout() async {
    setState(() => _isFinished = true);

    final results = widget.workoutPlan.exercises
        .map((exercise) => ExerciseResult(
      exercise: exercise,
      achievedOutput: _results[exercise] ?? 0,
    ))
        .toList();

    if (widget.inviteCode != null) {
      // Submit to Firebase for group workouts
      await _workoutService.submitWorkoutResults(
        widget.inviteCode!,
        'currentUserId', // Replace with actual user ID
        results,
      );
    } else {
      // Save to local database for solo workouts
      Provider.of<WorkoutState>(context, listen: false).addWorkout(
        Workout(date: DateTime.now(), results: results),
      );
    }

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
          _buildInviteCode(),
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
                onPressed: _isFinished
                    ? null
                    : _results.length == widget.workoutPlan.exercises.length
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