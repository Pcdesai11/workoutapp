// lib/pages/join_workout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../models/workout_plan.dart';
import '../services/firebase_auth.dart';
import '../services/group_workout_services.dart';
import 'workout_recording_page.dart';

class JoinWorkoutPage extends StatefulWidget {
  const JoinWorkoutPage({Key? key}) : super(key: key);

  @override
  State<JoinWorkoutPage> createState() => _JoinWorkoutPageState();
}

class _JoinWorkoutPageState extends State<JoinWorkoutPage> {
  final _inviteCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workoutService = GroupWorkoutService();
      final authService = AuthService();
      final userId = await authService.getOrCreateAnonymousUser();
      final inviteCode = _inviteCodeController.text.trim();

      final workoutPlan = await workoutService.joinGroupWorkout(inviteCode, userId);

      if (workoutPlan == null) {
        setState(() {
          _error = 'Invalid invite code or workout not found';
          _isLoading = false;
        });
        return;
      }

      final groupWorkoutStream = workoutService.streamWorkoutResults(inviteCode);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutRecordingPage(
              workoutPlan: workoutPlan,
              inviteCode: inviteCode,
              groupWorkoutStream: groupWorkoutStream,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error joining workout: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the invite code shared by your workout partner',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _inviteCodeController,
                decoration: const InputDecoration(
                  labelText: 'Invite Code',
                  hintText: 'e.g. ABC123',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the invite code';
                  }
                  if (value.length < 6) {
                    return 'Invite code must be 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinWorkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('JOIN WORKOUT'),
              ),
              // Add this button to JoinWorkoutPage's build method
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('SCAN QR CODE'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  try {
                    final qrCode = await FlutterBarcodeScanner.scanBarcode(
                      '#FF6666',
                      'Cancel',
                      true,
                      ScanMode.QR,
                    );

                    if (qrCode != '-1') {
                      _inviteCodeController.text = qrCode;
                      _joinWorkout();
                    }
                  } catch (e) {
                    setState(() {
                      _error = 'Error scanning QR code: $e';
                    });
                  }
                },
              )

            ],
          ),
        ),
      ),
    );
  }
}