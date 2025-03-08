import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../models/workout_plan.dart';
import '../models/group_workout.dart';
import '../services/group_workout_services.dart';
import '../services/firebase_auth.dart';
import '../state/workout_state.dart';
import '../widgets/exercise_inputs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<Exercise, double> _results = {};
  final GroupWorkoutService _workoutService = GroupWorkoutService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _groupResults;
  bool _isFinished = false;
  bool _isSubmitting = false;
  int? _previousParticipantCount;
  @override
  void initState() {
    super.initState();
    if (widget.groupWorkoutStream != null) {
      widget.groupWorkoutStream!.listen((results) {
        setState(() {
          _groupResults = results;
        });
      });
    } else if (widget.inviteCode != null) {
      // If no stream was provided but we have an invite code, set up our own stream
      _workoutService.streamWorkoutResults(widget.inviteCode!).listen((results) {
        setState(() {
          _groupResults = results;
        });
      });
    }
    _listenForGroupChanges();
  }
  void _listenForGroupChanges() {
    if (widget.inviteCode == null) return;

    // Listen for participant changes
    _workoutService.streamParticipantChanges(widget.inviteCode!).listen((participants) {
      // Only show notification if participants increased (someone joined)
      if (_previousParticipantCount != null &&
          participants.length > _previousParticipantCount!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New participant joined!')),
        );
      }
      _previousParticipantCount = participants.length;
    });

    // Listen for result changes
    _workoutService.streamResultChanges(widget.inviteCode!).listen((results) {
      // Process notifications about new results
      // Implementation depends on your data structure
    });
  }

  Future<void> _scanQrCode() async {
    try {
      final qrCode = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666',
        'Cancel',
        true,
        ScanMode.QR,
      );
      if (qrCode != '-1') {
        // -1 is returned when scanning is canceled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned code: $qrCode')),
        );

        // Join the workout using the scanned code
        try {
          final userId = _authService.getCurrentUserId();
          if (userId != null) {
            final workoutPlan = await _workoutService.joinGroupWorkout(qrCode, userId);
            if (workoutPlan != null) {
              // Navigate to a new workout recording page with the joined workout
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => WorkoutRecordingPage(
                    workoutPlan: workoutPlan,
                    inviteCode: qrCode,
                    groupWorkoutStream: _workoutService.streamWorkoutResults(qrCode),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid workout code')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You need to be signed in to join a workout')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error joining workout: $e')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning: $e')),
      );
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
                    Clipboard.setData(ClipboardData(text: widget.inviteCode!));
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
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('SHARE CODE'),
              onPressed: () {
                Share.share(
                    'Join my "${widget.workoutPlan.name}" workout with code: ${widget.inviteCode!}'
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupResults() {
    if (_groupResults == null) return const SizedBox.shrink();

    final results = _groupResults!['results'] as Map<String, dynamic>;
    final isCollaborative = _groupResults!['isCollaborative'] as bool;
    final participants = _groupResults!['participants'] as List;

    if (results.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Group Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('Waiting for participants to submit results...'),
              const SizedBox(height: 8),
              Text('${participants.length} participants joined'),
            ],
          ),
        ),
      );
    }

    // For collaborative workouts with results
    if (isCollaborative && results.isNotEmpty) {
      // Calculate aggregated results
      final aggregatedResults = <String, double>{};
      results.values.forEach((userResults) {
        (userResults as Map<String, dynamic>).forEach((exercise, value) {
          aggregatedResults[exercise] = (aggregatedResults[exercise] ?? 0.0) + (value as num).toDouble();
        });
      });

      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Group Progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Chip(
                    label: Text(
                      'Collaborative',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('${participants.length} participants joined'),
              const SizedBox(height: 8),
              const Divider(),
              ...results.entries.map((entry) {
                final userId = entry.key;
                final userResults = entry.value as Map<String, dynamic>;

                // Calculate completion percentage
                final exercisesCompleted = userResults.length;
                final totalExercises = widget.workoutPlan.exercises.length;
                final completionPercentage = totalExercises > 0
                    ? exercisesCompleted / totalExercises
                    : 0.0;

                // Determine if this is the current user
                final isCurrentUser = userId == _authService.getCurrentUserId();

                return ListTile(
                  title: Text(isCurrentUser ? 'You' : 'Participant'),
                  subtitle: Text('Completed: $exercisesCompleted/$totalExercises'),
                  trailing: SizedBox(
                    width: 80,
                    child: Row(
                      children: [
                        if (isCurrentUser)
                          const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: CircularProgressIndicator(
                            value: completionPercentage,
                            color: isCurrentUser ? Colors.blue : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  tileColor: isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
                );
              }).toList(),
              const Divider(),
              const Text('Group Total Progress:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.workoutPlan.exercises.map((exercise) {
                final achieved = aggregatedResults[exercise.name] ?? 0.0;
                final isSuccessful = achieved >= exercise.targetOutput;

                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text('${achieved.toStringAsFixed(1)}/${exercise.targetOutput} ${_getUnitText(exercise.unit)}'),
                  trailing: Icon(
                    isSuccessful ? Icons.check_circle : Icons.incomplete_circle,
                    color: isSuccessful ? Colors.green : Colors.grey,
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // For competitive workouts with results
    if (!isCollaborative && results.isNotEmpty) {
      final rankings = _workoutService.calculateRankings(results);
      final currentUserId = _authService.getCurrentUserId();

      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Group Progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Chip(
                    label: Text(
                      'Competitive',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('${participants.length} participants joined'),
              const SizedBox(height: 8),
              const Divider(),
              ...results.entries.map((entry) {
                final userId = entry.key;
                final userResults = entry.value as Map<String, dynamic>;

                // Calculate completion percentage
                final exercisesCompleted = userResults.length;
                final totalExercises = widget.workoutPlan.exercises.length;
                final completionPercentage = totalExercises > 0
                    ? exercisesCompleted / totalExercises
                    : 0.0;

                // Determine if this is the current user
                final isCurrentUser = userId == _authService.getCurrentUserId();

                return ListTile(
                  title: Text(isCurrentUser ? 'You' : 'Participant'),
                  subtitle: Text('Completed: $exercisesCompleted/$totalExercises'),
                  trailing: SizedBox(
                    width: 80,
                    child: Row(
                      children: [
                        if (isCurrentUser)
                          const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: CircularProgressIndicator(
                            value: completionPercentage,
                            color: isCurrentUser ? Colors.blue : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  tileColor: isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
                );
              }).toList(),
              const Divider(),
              const Text('Rankings:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...rankings.entries.map((entry) {
                final isCurrentUser = entry.key == currentUserId;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: entry.value == 1 ? Colors.yellow :
                    entry.value == 2 ? Colors.grey :
                    entry.value == 3 ? Colors.orange : Colors.blue.withOpacity(0.2),
                    child: Text('${entry.value}'),
                  ),
                  title: Text(isCurrentUser ? 'You' : 'Participant'),
                  trailing: isCurrentUser ? const Icon(Icons.person, color: Colors.blue) : null,
                  tileColor: isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
                );
              }),
            ],
          ),
        ),
      );
    }

    // Default case - this should not be reached if the logic above is correct
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No results available'),
      ),
    );
  }

  Widget _buildExercisesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.workoutPlan.exercises.length,
      itemBuilder: (context, index) {
        final exercise = widget.workoutPlan.exercises[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Target: ${exercise.targetOutput} ${_getUnitText(exercise.unit)}'),
                const SizedBox(height: 16),
                ExerciseInputs(
                  exercise: exercise,
                  onResultUpdated: (value) {
                    setState(() {
                      _results[exercise] = value;
                    });

                    if (widget.inviteCode != null) {
                      _updateGroupWorkout();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getUnitText(MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.repetitions:
        return 'reps';
      case MeasurementUnit.seconds:
        return 'sec';
      case MeasurementUnit.meters:
        return 'm';
      default:
        return '';
    }
  }
  Widget _buildParticipantsList() {
    if (_groupResults == null) return const SizedBox.shrink();

    final participants = _groupResults!['participants'] as List;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants (${participants.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            participants.isEmpty
                ? const Text('Waiting for people to join...')
                : Column(
              children: List.generate(
                participants.length,
                    (index) => ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    participants[index] == _authService.getCurrentUserId()
                        ? 'You'
                        : 'Participant ${index + 1}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _updateGroupWorkout() async {
    final userId = _authService.getCurrentUserId();
    if (userId == null || widget.inviteCode == null) return;

    // Convert results to a map format acceptable for Firestore
    final Map<String, dynamic> resultMap = {};
    for (var entry in _results.entries) {
      resultMap[entry.key.name] = entry.value;
    }

    // Update results in Firestore
    await _firestore.collection('group_workouts').doc(widget.inviteCode).update({
      'results.$userId': resultMap,
    });
  }

  Future<void> _finishWorkout() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = _authService.getCurrentUserId();

      if (userId != null) {
        // Create ExerciseResult objects for each completed exercise
        final exerciseResults = _results.entries.map((entry) =>
            ExerciseResult(
              exercise: entry.key,
              achievedOutput: entry.value,
            )
        ).toList();

        // Create a Workout object
        final workout = Workout(
          date: DateTime.now(),
          results: exerciseResults,
        );

        // Save workout to your storage/state management system
        Provider.of<WorkoutState>(context, listen: false).addWorkout(workout);

        if (widget.inviteCode != null) {
          // Submit results to the group workout
          await _workoutService.submitWorkoutResults(
            widget.inviteCode!,
            userId,
            exerciseResults,
          );
        }

        setState(() {
          _isFinished = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout: $e')),
      );
    }
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Workout Completed!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Great job finishing "${widget.workoutPlan.name}"',
            textAlign: TextAlign.center,
          ),
          if (widget.inviteCode != null) ...[
            const SizedBox(height: 16),
            Text(
              'Your results have been shared with the group',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('BACK TO HOME'),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutPlan.name),
        actions: [
          if (widget.inviteCode != null)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanQrCode,
            ),
        ],
      ),
      body: _isFinished
          ? _buildCompletionScreen()
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildInviteCode(),
            _buildGroupResults(),
            _buildExercisesList(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _finishWorkout,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('FINISH WORKOUT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}