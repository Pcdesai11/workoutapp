import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/models.dart';

class ExerciseInputs extends StatelessWidget {
  final Exercise exercise;
  final Function(double) onResultUpdated;

  const ExerciseInputs({
    Key? key,
    required this.exercise,
    required this.onResultUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (exercise.unit) {
      case MeasurementUnit.seconds:
        return TimerInput(
          onValueChanged: onResultUpdated,
          targetValue: exercise.targetOutput,
        );
      case MeasurementUnit.repetitions:
        return RepCounter(
          onValueChanged: onResultUpdated,
          targetValue: exercise.targetOutput,
        );
      case MeasurementUnit.meters:
        return DistanceInput(
          onValueChanged: onResultUpdated,
          targetValue: exercise.targetOutput,
        );
      default:
        return SliderInput(
          onValueChanged: onResultUpdated,
          targetValue: exercise.targetOutput,
        );
    }
  }
}

class TimerInput extends StatefulWidget {
  final void Function(double) onValueChanged;
  final double targetValue;

  const TimerInput({
    Key? key,
    required this.onValueChanged,
    required this.targetValue,
  }) : super(key: key);

  @override
  State<TimerInput> createState() => _TimerInputState();
}

class _TimerInputState extends State<TimerInput> {
  int _seconds = 0;
  bool _isRunning = false;
  late Stopwatch _stopwatch;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStop() {
    setState(() {
      if (_isRunning) {
        _stopwatch.stop();
        _timer?.cancel();
        _seconds = _stopwatch.elapsedMilliseconds ~/ 1000;
        widget.onValueChanged(_seconds.toDouble());
      } else {
        _stopwatch.reset();
        _stopwatch.start();

        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {

          });
        });
      }
      _isRunning = !_isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSeconds = _isRunning
        ? _stopwatch.elapsedMilliseconds / 1000
        : _seconds.toDouble();

    return Column(
      children: [
        Text(
          _isRunning
              ? '${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)} seconds'
              : '$_seconds seconds',
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _startStop,
          icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
          label: Text(_isRunning ? 'Stop' : 'Start'),
        ),
        const SizedBox(height: 8),
        // Add the progress indicator here
        ExerciseProgressIndicator(
          currentValue: currentSeconds,
          targetValue: widget.targetValue,
        ),
      ],
    );
  }
}

class RepCounter extends StatefulWidget {
  final void Function(double) onValueChanged;
  final double targetValue;

  const RepCounter({
    Key? key,
    required this.onValueChanged,
    required this.targetValue,
  }) : super(key: key);

  @override
  State<RepCounter> createState() => _RepCounterState();
}

class _RepCounterState extends State<RepCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              mini: true,
              onPressed: () {
                setState(() {
                  if (_count > 0) {
                    _count--;
                    widget.onValueChanged(_count.toDouble());
                  }
                });
              },
              child: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$_count',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            FloatingActionButton(
              mini: true,
              onPressed: () {
                setState(() {
                  _count++;
                  widget.onValueChanged(_count.toDouble());
                });
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Add the progress indicator
        ExerciseProgressIndicator(
          currentValue: _count.toDouble(),
          targetValue: widget.targetValue,
        ),
      ],
    );
  }
}

class DistanceInput extends StatefulWidget {
  final void Function(double) onValueChanged;
  final double targetValue;

  const DistanceInput({
    Key? key,
    required this.onValueChanged,
    required this.targetValue,
  }) : super(key: key);

  @override
  State<DistanceInput> createState() => _DistanceInputState();
}

class _DistanceInputState extends State<DistanceInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distance = double.tryParse(_controller.text) ?? 0;

    return Column(
      children: [
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Enter distance',
            suffixText: 'meters',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            final distance = double.tryParse(value) ?? 0;
            widget.onValueChanged(distance);
            // This will trigger a rebuild to update the progress indicator
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        // Add the progress indicator
        ExerciseProgressIndicator(
          currentValue: distance,
          targetValue: widget.targetValue,
        ),
      ],
    );
  }
}


class StepCounter extends StatefulWidget {
  final void Function(double) onValueChanged;
  final double targetValue;

  const StepCounter({
    Key? key,
    required this.onValueChanged,
    required this.targetValue,
  }) : super(key: key);

  @override
  State<StepCounter> createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  int _steps = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$_steps steps',
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              setState(() {
                _steps++;
                widget.onValueChanged(_steps.toDouble());
              });
            },
            child: const Text('TAP TO COUNT STEP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        // Add the progress indicator
        ExerciseProgressIndicator(
          currentValue: _steps.toDouble(),
          targetValue: widget.targetValue,
        ),
      ],
    );
  }
}

class SliderInput extends StatefulWidget {
  final void Function(double) onValueChanged;
  final double targetValue;

  const SliderInput({
    Key? key,
    required this.onValueChanged,
    required this.targetValue,
  }) : super(key: key);

  @override
  State<SliderInput> createState() => _SliderInputState();
}

class _SliderInputState extends State<SliderInput> {
  double _value = 0;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${_value.toInt()} reps',
          style: const TextStyle(fontSize: 24),
        ),
        Slider(
          value: _value,
          min: 0,
          max: widget.targetValue * 1.5,
          divisions: (widget.targetValue * 1.5).toInt(),
          label: _value.round().toString(),
          onChanged: (value) {
            setState(() {
              _value = value;
              widget.onValueChanged(value);
            });
          },
        ),
        const SizedBox(height: 8),
        // Add the progress indicator
        ExerciseProgressIndicator(
          currentValue: _value,
          targetValue: widget.targetValue,
        ),
      ],
    );
  }
}
class ExerciseProgressIndicator extends StatelessWidget {
  final double currentValue;
  final double targetValue;

  const ExerciseProgressIndicator({
    Key? key,
    required this.currentValue,
    required this.targetValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = currentValue / targetValue;
    final isSuccessful = currentValue >= targetValue;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress: ${(progress * 100).toStringAsFixed(0)}%'),
              Text(isSuccessful ? 'Completed!' : 'In progress...'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isSuccessful ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}