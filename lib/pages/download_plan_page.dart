import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../models/workout_plan.dart';
import '../models/models.dart';
import '../state/workout_state.dart';

class DownloadPlanPage extends StatefulWidget {
  final AppDatabase database;

  const DownloadPlanPage({Key? key, required this.database}) : super(key: key);

  @override
  State<DownloadPlanPage> createState() => _DownloadPlanPageState();
}

class _DownloadPlanPageState extends State<DownloadPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  WorkoutPlan? _downloadedPlan;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _downloadPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _downloadedPlan = null;
    });

    try {
      final response = await http.get(Uri.parse(_urlController.text));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse the workout plan from the response
        if (data['name'] != null && data['exercises'] != null) {
          final exercises = (data['exercises'] as List).map((e) {
            // Use the correct key "target" instead of "targetOutput"
            final target = e['target'] ?? 0.0; // Default to 0.0 if null
            return Exercise(
              name: e['name'],
              targetOutput: target.toDouble(),
              unit: _parseUnit(e['unit']),
            );
          }).toList();

          setState(() {
            _downloadedPlan = WorkoutPlan(
              name: data['name'],
              exercises: exercises,
            );
          });
        } else {
          setState(() {
            _error = 'Invalid workout plan format';
          });
        }
      } else {
        setState(() {
          _error = 'Failed to download: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  MeasurementUnit _parseUnit(String unit) {
    switch (unit) {
      case 'seconds':
        return MeasurementUnit.seconds;
      case 'repetitions':
        return MeasurementUnit.repetitions;
      case 'meters':
        return MeasurementUnit.meters;
      default:
        return MeasurementUnit.repetitions;
    }
  }

  void _savePlan() {
    if (_downloadedPlan != null) {
      Provider.of<WorkoutState>(context, listen: false)
          .savePlan(_downloadedPlan!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout plan saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Workout Plan'),
      ),
      backgroundColor: const Color(0xFFFFF4E1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Workout Plan URL',
                  hintText: 'https://example.com/workout-plan.json',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URL';
                  }
                  try {
                    final uri = Uri.parse(value);
                    if (!uri.isAbsolute) {
                      return 'Please enter a valid URL';
                    }
                  } catch (e) {
                    return 'Invalid URL format';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _downloadPlan,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('DOWNLOAD PLAN'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (_downloadedPlan != null) ...[
              const SizedBox(height: 24),
              Text(
                'Downloaded Plan: ${_downloadedPlan!.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${_downloadedPlan!.exercises.length} exercises',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Exercises:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._downloadedPlan!.exercises.map((exercise) {
                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text(
                      'Target: ${exercise.targetOutput} ${exercise.unit.name}'),
                );
              }).toList(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _downloadedPlan = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('DISCARD'),
                  ),
                  ElevatedButton(
                    onPressed: _savePlan,
                    child: const Text('SAVE PLAN'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}