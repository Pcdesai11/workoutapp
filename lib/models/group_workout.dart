
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

enum WorkoutType {
  solo,
  collaborative,
  competitive
}

class GroupWorkoutResult {
  final String userId;
  final Map<String, double> exerciseResults;
  final int? ranking;

  GroupWorkoutResult({
    required this.userId,
    required this.exerciseResults,
    this.ranking,
  });

  factory GroupWorkoutResult.fromMap(String userId, Map<String, dynamic> data) {
    return GroupWorkoutResult(
      userId: userId,
      exerciseResults: Map<String, double>.from(data),
      ranking: null,
    );
  }

  factory GroupWorkoutResult.fromMapWithRanking(
      String userId, Map<String, dynamic> data, int ranking) {
    return GroupWorkoutResult(
      userId: userId,
      exerciseResults: Map<String, double>.from(data),
      ranking: ranking,
    );
  }
}

class GroupWorkout {
  final String inviteCode;
  final String creatorId;
  final WorkoutType type;
  final DateTime createdAt;
  final List<String> participants;
  final Map<String, GroupWorkoutResult> results;

  GroupWorkout({
    required this.inviteCode,
    required this.creatorId,
    required this.type,
    required this.createdAt,
    required this.participants,
    required this.results,
  });

  factory GroupWorkout.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final isCollaborative = data['isCollaborative'] as bool;
    final type = isCollaborative
        ? WorkoutType.collaborative
        : WorkoutType.competitive;
    final participants = List<String>.from(data['participants'] ?? []);

    final resultsData = data['results'] as Map<String, dynamic>? ?? {};
    final results = <String, GroupWorkoutResult>{};

    for (var entry in resultsData.entries) {
      final userId = entry.key;
      final userResults = entry.value as Map<String, dynamic>;
      results[userId] = GroupWorkoutResult.fromMap(userId, userResults);
    }

    return GroupWorkout(
      inviteCode: doc.id,
      creatorId: data['creatorId'] ?? '',
      type: type,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participants: participants,
      results: results,
    );
  }
}