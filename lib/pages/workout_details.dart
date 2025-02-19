import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class WorkoutDetails extends StatelessWidget {
  final Workout workout;

  const WorkoutDetails({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMd();

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout on ${dateFormat.format(workout.date)}'),
      ),
      backgroundColor: const Color(0xFFFFF4E1),
      body: ListView.builder(
        itemCount: workout.results.length,
        itemBuilder: (context, index) {
          final result = workout.results[index];
          final isSuccessful = result.isSuccessful;

          return ListTile(
            title: Text(result.exercise.name),
            subtitle: Text(
              'Target: ${result.exercise.targetOutput} ${result.exercise.unit.name}, '
                  'Achieved: ${result.achievedOutput} ${result.exercise.unit.name}',
            ),
            trailing: Icon(
              isSuccessful ? Icons.check_circle : Icons.error,
              color: isSuccessful ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }
}