import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
    return Row(
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
    return TextField(
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
      },
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
      ],
    );
  }
}