
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../models/group_workout.dart';
import '../services/group_workout_services.dart';

class WorkoutDetails extends StatelessWidget {
  final Workout workout;
  final String? inviteCode;
  final WorkoutType? workoutType;

  const WorkoutDetails({
    super.key,
    required this.workout,
    this.inviteCode,
    this.workoutType,
  });

  Widget _buildGroupWorkoutHeader(BuildContext context, Map<String, dynamic> groupData) {
    final participantCount = (groupData['participants'] as List).length;
    final isCollaborative = groupData['isCollaborative'] as bool;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCollaborative ? Icons.group : Icons.emoji_events,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isCollaborative ? 'Collaborative Workout' : 'Competitive Workout',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$participantCount ${participantCount == 1 ? 'participant' : 'participants'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitiveResults(BuildContext context, Map<String, dynamic> resultsData) {
    final userId = 'currentUserId'; // Replace with actual user ID
    final rankings = (resultsData['results'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, (value as Map<String, dynamic>)['ranking'] as int));

    final userRank = rankings[userId] ?? 0;
    final totalParticipants = rankings.length;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Your Ranking',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$userRank of $totalParticipants',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _getRankColor(userRank),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMd();

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout on ${dateFormat.format(workout.date)}'),
      ),
      body: inviteCode != null
          ? StreamBuilder<Map<String, dynamic>>(
        stream: GroupWorkoutService().streamWorkoutResults(inviteCode!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupData = snapshot.data!;
          final isCollaborative = groupData['isCollaborative'] as bool;

          return Column(
            children: [
              _buildGroupWorkoutHeader(context, groupData),
              if (!isCollaborative)
                _buildCompetitiveResults(context, groupData),
              Expanded(
                child: ListView.builder(
                  itemCount: workout.results.length,
                  itemBuilder: (context, index) {
                    final result = workout.results[index];
                    final groupResults = groupData['results'] as Map<String, dynamic>;

                    double totalOutput = 0;
                    if (isCollaborative) {
                      groupResults.values.forEach((userResults) {
                        totalOutput += (userResults[result.exercise.name] ?? 0) as double;
                      });
                    }

                    return ListTile(
                      title: Text(result.exercise.name),
                      subtitle: Text(
                        isCollaborative
                            ? 'Group total: $totalOutput ${result.exercise.unit.name}\n'
                            'Your contribution: ${result.achievedOutput} ${result.exercise.unit.name}'
                            : 'Your result: ${result.achievedOutput} ${result.exercise.unit.name}',
                      ),
                      trailing: Icon(
                        isCollaborative
                            ? (totalOutput >= result.exercise.targetOutput
                            ? Icons.check_circle
                            : Icons.error)
                            : (result.isSuccessful
                            ? Icons.check_circle
                            : Icons.error),
                        color: isCollaborative
                            ? (totalOutput >= result.exercise.targetOutput
                            ? Colors.green
                            : Colors.red)
                            : (result.isSuccessful
                            ? Colors.green
                            : Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      )
          : ListView.builder(
        itemCount: workout.results.length,
        itemBuilder: (context, index) {
          final result = workout.results[index];
          return ListTile(
            title: Text(result.exercise.name),
            subtitle: Text(
              'Target: ${result.exercise.targetOutput} ${result.exercise.unit.name}, '
                  'Achieved: ${result.achievedOutput} ${result.exercise.unit.name}',
            ),
            trailing: Icon(
              result.isSuccessful ? Icons.check_circle : Icons.error,
              color: result.isSuccessful ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }
}