
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';

class WorkoutCompleteDialog extends StatelessWidget {
  final Workout workout;
  final Map<String, dynamic>? statistics;

  const WorkoutCompleteDialog({
    super.key,
    required this.workout,
    this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Workout Complete!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Completed Successfully',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (statistics != null) ...[
            const Text('Workout Statistics:'),
            const SizedBox(height: 8),
            _buildStatistics(context),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop('share'),
          child: const Text('Share Results'),
        ),
        TextButton(
          onPressed: () => context.pop('close'),
          child: Text(
            'Close',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    if (statistics == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: statistics!.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatStatKey(entry.key),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_formatStatValue(entry.value)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatStatKey(String key) {

    return key
        .replaceAllMapped(
      RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
    )
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty
        ? word[0].toUpperCase() + word.substring(1)
        : '')
        .join(' ');
  }

  String _formatStatValue(dynamic value) {
    if (value is Duration) {

      final minutes = value.inMinutes;
      final seconds = value.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else if (value is double) {

      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}