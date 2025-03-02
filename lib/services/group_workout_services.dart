import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/models.dart';
import '../models/workout_plan.dart';

class GroupWorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a unique 6-character invite code using the workout plan name and timestamp
  String generateInviteCode(String workoutName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(workoutName + timestamp);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 6).toUpperCase();
  }

  // Create a new group workout in Firestore
  Future<String> createGroupWorkout({
    required WorkoutPlan plan,
    required bool isCollaborative,
    required String creatorId,
  }) async {
    final inviteCode = generateInviteCode(plan.name);

    await _firestore.collection('group_workouts').doc(inviteCode).set({
      'planName': plan.name,
      'exercises': plan.exercises.map((e) => {
        'name': e.name,
        'targetOutput': e.targetOutput,
        'unit': e.unit.toString(),
      }).toList(),
      'isCollaborative': isCollaborative,
      'creatorId': creatorId,
      'createdAt': FieldValue.serverTimestamp(),
      'participants': [],
      'results': {},
    });

    return inviteCode;
  }

  // Join an existing group workout
  Future<WorkoutPlan?> joinGroupWorkout(String inviteCode, String userId) async {
    final doc = await _firestore.collection('group_workouts').doc(inviteCode).get();

    if (!doc.exists) return null;

    final data = doc.data()!;

    // Add participant if not already present
    await _firestore.collection('group_workouts').doc(inviteCode).update({
      'participants': FieldValue.arrayUnion([userId])
    });

    // Convert Firestore data back to WorkoutPlan
    return WorkoutPlan(
      name: data['planName'],
      exercises: (data['exercises'] as List).map((e) => Exercise(
        name: e['name'],
        targetOutput: e['targetOutput'],
        unit: MeasurementUnit.values.firstWhere(
                (u) => u.toString() == e['unit']
        ),
      )).toList(),
    );
  }

  // Submit results for a group workout
  Future<void> submitWorkoutResults(
      String inviteCode,
      String userId,
      List<ExerciseResult> results,
      ) async {
    final resultsMap = {
      for (var result in results)
        result.exercise.name: result.achievedOutput
    };

    await _firestore.collection('group_workouts').doc(inviteCode).update({
      'results.$userId': resultsMap,
    });
  }

  // Get aggregated results for a group workout
  Future<Map<String, dynamic>> getWorkoutResults(String inviteCode) async {
    final doc = await _firestore.collection('group_workouts').doc(inviteCode).get();
    if (!doc.exists) throw Exception('Workout not found');

    final data = doc.data()!;
    final results = data['results'] as Map<String, dynamic>;
    final isCollaborative = data['isCollaborative'] as bool;
    final participants = (data['participants'] as List).cast<String>();

    if (isCollaborative) {
      // Sum up all participants' results for each exercise
      final aggregatedResults = <String, double>{};

      results.values.forEach((userResults) {
        (userResults as Map<String, dynamic>).forEach((exercise, value) {
          aggregatedResults[exercise] = (aggregatedResults[exercise] ?? 0.0) + (value as num).toDouble();
        });
      });

      return {
        'type': 'collaborative',
        'participantCount': participants.length,
        'results': aggregatedResults,
      };
    } else {
      // For competitive, return individual results and rankings
      final competitiveResults = <String, Map<String, dynamic>>{};

      results.forEach((userId, userResults) {
        competitiveResults[userId] = {
          'results': userResults,
          'ranking': _calculateRanking(userId, results),
        };
      });

      return {
        'type': 'competitive',
        'participantCount': participants.length,
        'results': competitiveResults,
      };
    }
  }

  // Calculate user ranking based on total achievement percentage
  int _calculateRanking(String userId, Map<String, dynamic> allResults) {
    final scores = allResults.entries.map((entry) {
      final userResults = entry.value as Map<String, dynamic>;
      return MapEntry(
          entry.key,
          userResults.values.fold<double>(0, (sum, value) => sum + (value as num).toDouble())
      );
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scores.indexWhere((entry) => entry.key == userId) + 1;
  }

  // Stream workout results for real-time updates
  Stream<Map<String, dynamic>> streamWorkoutResults(String inviteCode) {
    return _firestore
        .collection('group_workouts')
        .doc(inviteCode)
        .snapshots()
        .map((doc) {
      final data = doc.data()!;
      return {
        'isCollaborative': data['isCollaborative'],
        'results': data['results'] ?? {},
        'participants': data['participants'] ?? [],
      };
    });
  }
}