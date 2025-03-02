// lib/models/group_workout.dart
import 'package:workoutapp/models/workout_plan.dart';

enum WorkoutType {
  solo,
  collaborative,
  competitive
}

class GroupWorkout {
  final String inviteCode;
  final WorkoutPlan plan;
  final WorkoutType type;
  final String creatorId;
  final DateTime createdAt;
  final List<String> participants;
  final Map<String, Map<String, double>> results;

  GroupWorkout({
    required this.inviteCode,
    required this.plan,
    required this.type,
    required this.creatorId,
    required this.createdAt,
    this.participants = const [],
    this.results = const {},
  });

  bool get isCollaborative => type == WorkoutType.collaborative;
  bool get isCompetitive => type == WorkoutType.competitive;

  Map<String, double> getAggregatedResults() {
    if (!isCollaborative) return {};

    final aggregated = <String, double>{};
    for (var userResults in results.values) {
      for (var entry in userResults.entries) {
        aggregated[entry.key] = (aggregated[entry.key] ?? 0) + entry.value;
      }
    }
    return aggregated;
  }

  List<MapEntry<String, int>> getCompetitiveRankings() {
    if (!isCompetitive) return [];

    // Calculate total scores for each participant
    final scores = results.map((userId, results) {
      final total = results.values.fold<double>(0, (sum, value) => sum + value);
      return MapEntry(userId, total);
    }).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Convert to rankings
    return scores.asMap().entries
        .map((e) => MapEntry(e.value.key, e.key + 1))
        .toList();
  }
}