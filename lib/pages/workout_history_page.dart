
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../state/workout_state.dart';
import '../widgets/recent_performance_widget.dart';
import '../models/workout_plan.dart';
import '../services/firebase_auth.dart';
import '../services/group_workout_services.dart';

class WorkoutHistoryPage extends StatelessWidget {
  const WorkoutHistoryPage({super.key});


  Future<String> _getOrCreateAnonymousUser() async {
    try {
      final authService = AuthService();
      return await authService.getOrCreateAnonymousUser();
    } catch (e) {

      debugPrint('Error creating anonymous user: $e');
      return '';
    }
  }


  void _showWorkoutTypeSelector(BuildContext context, WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Workout Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Solo Workout'),
              subtitle: const Text('Work out on your own'),
              onTap: () {
                Navigator.pop(context);

                context.push(
                  '/workout-recording',
                  extra: {
                    'workoutPlan': plan,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Collaborative Workout'),
              subtitle: const Text('Work together to reach targets'),
              onTap: () {

                _handleGroupWorkout(context, plan, isCollaborative: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Competitive Workout'),
              subtitle: const Text('Compete against others'),
              onTap: () {

                _handleGroupWorkout(context, plan, isCollaborative: false);
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _handleGroupWorkout(
      BuildContext context,
      WorkoutPlan plan,
      {required bool isCollaborative}
      ) async {

    Navigator.pop(context);


    final scaffoldMessenger = ScaffoldMessenger.of(context);


    bool hasShownSnackbar = false;


    bool hasNavigated = false;


    BuildContext? dialogContext;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Setting up workout session...'),
              ],
            ),
          );
        },
      );
    }


    bool isTimedOut = false;
    Future.delayed(const Duration(seconds: 2), () {
      isTimedOut = true;


      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }


      if (!hasShownSnackbar && !hasNavigated) {
        hasShownSnackbar = true;
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            content: const Text('The QR code is generated now. Select your Workout once again.'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                if (context.mounted) {
                  _showWorkoutTypeSelector(context, plan);
                }
              },
            ),
          ),
        );
      }
    });

    try {

      print('Starting group workout setup...');


      final authService = AuthService();
      print('Getting anonymous user...');
      final userId = await authService.getOrCreateAnonymousUser();
      print('User ID obtained: ${userId.substring(0, 4)}...');


      final workoutService = GroupWorkoutService();
      print('Creating group workout...');
      final inviteCode = await workoutService.createGroupWorkout(
        plan: plan,
        isCollaborative: isCollaborative,
        creatorId: userId,
      );
      print('Group workout created with code: $inviteCode');


      print('Setting up workout results stream...');
      final groupWorkoutStream = workoutService.streamWorkoutResults(inviteCode);
      print('Stream setup complete');


      if (isTimedOut) {
        print('Timeout occurred, aborting navigation');
        return;
      }


      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }


      if (context.mounted) {

        hasNavigated = true;


        Future.microtask(() {
          context.push(
            '/workout-recording',
            extra: {
              'workoutPlan': plan,
              'inviteCode': inviteCode,
              'groupWorkoutStream': groupWorkoutStream,
            },
          );
        });
      }
    } catch (e) {
      print('Error in _handleGroupWorkout: $e');


      if (isTimedOut) return;


      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }


      if (!hasShownSnackbar) {
        hasShownSnackbar = true;
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            content: const Text('Enjoy!'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                if (context.mounted) {
                  _showWorkoutTypeSelector(context, plan);
                }
              },
            ),
          ),
        );
      }


      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Workout Setup Error'),
            content: Text('Failed to create workout: ${e.toString()}\n\nPlease try again and share your QR code with participants.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
  void _showWorkoutPlanSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<WorkoutState>(
        builder: (context, workoutState, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Select Workout Plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: workoutState.availablePlans.length,
                    itemBuilder: (context, index) {
                      final plan = workoutState.availablePlans[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.fitness_center,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(plan.name),
                          subtitle: Text('${plan.exercises.length} exercises'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pop(context);
                            _showWorkoutTypeSelector(context, plan);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Download new plan',
            onPressed: () {

              context.push('/download-plan');
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'joinWorkout',
            mini: true,
            onPressed: () {

              context.push('/join-workout');
            },
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'startWorkout',
            onPressed: () => _showWorkoutPlanSelector(context),
            label: const Text('Start Workout'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          const RecentPerformanceWidget(),
          Expanded(
            child: Consumer<WorkoutState>(
              builder: (context, workoutState, child) {
                final workouts = workoutState.workouts;

                if (workouts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workouts recorded yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button below to start a new workout',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    final successfulResults = workout.results
                        .where((result) => result.isSuccessful)
                        .length;
                    final totalExercises = workout.results.length;
                    final successRate = totalExercises > 0
                        ? (successfulResults / totalExercises * 100).toStringAsFixed(0)
                        : "0";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {

                          context.push(
                            '/workout-details',
                            extra: workout,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFormat.format(workout.date),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: double.parse(successRate) >= 70
                                          ? Colors.green.withOpacity(0.1)
                                          : double.parse(successRate) >= 40
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$successRate% complete',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: double.parse(successRate) >= 70
                                            ? Colors.green
                                            : double.parse(successRate) >= 40
                                            ? Colors.orange
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$successfulResults of $totalExercises exercises completed',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: totalExercises > 0 ? successfulResults / totalExercises : 0.0,
                                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  double.parse(successRate) >= 70
                                      ? Colors.green
                                      : double.parse(successRate) >= 40
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}