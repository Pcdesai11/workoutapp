import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/models.dart';
import '../models/workout_plan.dart';

class GroupWorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  String generateInviteCode(String workoutName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(workoutName + timestamp);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 6).toUpperCase();
  }


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


  Future<WorkoutPlan?> joinGroupWorkout(String inviteCode, String userId) async {
    final doc = await _firestore.collection('group_workouts').doc(inviteCode).get();

    if (!doc.exists) return null;

    final data = doc.data()!;


    await _firestore.collection('group_workouts').doc(inviteCode).update({
      'participants': FieldValue.arrayUnion([userId])
    });


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


  Future<Map<String, dynamic>> getWorkoutResults(String inviteCode) async {
    final doc = await _firestore.collection('group_workouts').doc(inviteCode).get();
    if (!doc.exists) throw Exception('Workout not found');

    final data = doc.data()!;
    final results = data['results'] as Map<String, dynamic>;
    final isCollaborative = data['isCollaborative'] as bool;
    final participants = (data['participants'] as List).cast<String>();

    if (isCollaborative) {

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

  Map<String, int> calculateRankings(Map<String, dynamic> results) {

    final scores = results.entries.map((entry) {
      final userResults = entry.value as Map<String, dynamic>;
      final totalScore = userResults.values.fold<double>(
          0, (sum, value) => sum + (value as num).toDouble());
      return MapEntry(entry.key, totalScore);
    }).toList();


    scores.sort((a, b) => b.value.compareTo(a.value));


    final rankings = <String, int>{};
    for (int i = 0; i < scores.length; i++) {
      rankings[scores[i].key] = i + 1;
    }

    return rankings;
  }
  Stream<Map<String, dynamic>> streamExerciseProgress(String inviteCode) {
    return _firestore
        .collection('group_workouts')
        .doc(inviteCode)
        .snapshots()
        .map((doc) {
      final data = doc.data()!;
      final results = data['results'] as Map<String, dynamic>? ?? {};
      final isCollaborative = data['isCollaborative'] as bool? ?? false;


      Map<String, double> exerciseProgress = {};

      results.forEach((userId, userResults) {
        (userResults as Map<String, dynamic>).forEach((exercise, value) {
          if (isCollaborative) {
            exerciseProgress[exercise] = (exerciseProgress[exercise] ?? 0.0) + (value as num).toDouble();
          } else {

            exerciseProgress[exercise] = exerciseProgress[exercise] != null
                ? math.max(exerciseProgress[exercise]!, (value as num).toDouble())
                : (value as num).toDouble();
          }
        });
      });

      return {
        'exerciseProgress': exerciseProgress,
        'isCollaborative': isCollaborative
      };
    });
  }
  Future<Map<String, dynamic>> getGroupStatistics(String inviteCode) async {
    final doc = await _firestore.collection('group_workouts').doc(inviteCode).get();
    if (!doc.exists) throw Exception('Workout not found');

    final data = doc.data()!;
    final results = data['results'] as Map<String, dynamic>? ?? {};
    final exercises = data['exercises'] as List? ?? [];


    final completionStats = <String, double>{};
    results.forEach((userId, userResults) {
      final completed = (userResults as Map<String, dynamic>).length;
      completionStats[userId] = exercises.isEmpty
          ? 0.0
          : (completed / exercises.length) * 100;
    });


    String? topPerformer;
    double topScore = 0;

    if (!(data['isCollaborative'] as bool? ?? true)) {
      results.forEach((userId, userResults) {
        final userScore = (userResults as Map<String, dynamic>).values
            .fold<double>(0, (sum, val) => sum + (val as num).toDouble());

        if (userScore > topScore) {
          topScore = userScore;
          topPerformer = userId;
        }
      });
    }

    return {
      'completionStats': completionStats,
      'topPerformer': topPerformer,
      'topScore': topScore,
      'participantCount': (data['participants'] as List? ?? []).length,
    };

  }

  Stream<List<String>> streamParticipantChanges(String inviteCode) {
    return _firestore
        .collection('group_workouts')
        .doc(inviteCode)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data()!;
      return (data['participants'] as List? ?? []).cast<String>();
    });
  }


  Stream<Map<String, dynamic>> streamResultChanges(String inviteCode) {
    return _firestore
        .collection('group_workouts')
        .doc(inviteCode)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {};
      final data = doc.data()!;
      return data['results'] as Map<String, dynamic>? ?? {};
    });
  }

  Stream<Map<String, dynamic>> streamWorkoutResults(String inviteCode) {
    try {
      print('Creating workout results stream for code: $inviteCode');


      return _firestore
          .collection('group_workouts')
          .doc(inviteCode)
          .snapshots()
          .handleError((error) {
        print('Error in workout stream: $error');

        return {};
      })
          .map((doc) {
        if (!doc.exists) {
          print('Warning: Document does not exist for invite code: $inviteCode');
          return {
            'isCollaborative': false,
            'results': {},
            'participants': [],
            'error': 'Workout not found'
          };
        }

        final data = doc.data();
        if (data == null) {
          print('Warning: Document data is null for invite code: $inviteCode');
          return {
            'isCollaborative': false,
            'results': {},
            'participants': [],
            'error': 'Workout data is empty'
          };
        }

        print('Successfully mapped workout data for streaming');
        return {
          'isCollaborative': data['isCollaborative'] ?? false,
          'results': data['results'] ?? {},
          'participants': data['participants'] ?? [],
        };
      });
    } catch (e) {
      print('Critical error setting up workout stream: $e');

      return Stream.value({
        'isCollaborative': false,
        'results': {},
        'participants': [],
        'error': 'Failed to set up stream: ${e.toString()}'
      });
    }
  }
}