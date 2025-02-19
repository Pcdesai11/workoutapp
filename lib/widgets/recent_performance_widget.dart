import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/workout_state.dart';

class RecentPerformanceWidget extends StatelessWidget {
  const RecentPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutState>(
      builder: (context, workoutState, child) {
        final score = workoutState.getRecentPerformanceScore();
        final theme = Theme.of(context);

        Color getPerformanceColor() {
          if (score >= 75) return Colors.green;
          if (score >= 50) return Colors.orange;
          if (score > 0) return Colors.red;
          return theme.colorScheme.onSurface.withOpacity(0.6);
        }

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Performance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                score > 0
                    ? Row(
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(getPerformanceColor()),
                      strokeWidth: 8,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${score.toStringAsFixed(1)}%',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: getPerformanceColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'success rate',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                )
                    : Row(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'No workouts completed in the past week',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}