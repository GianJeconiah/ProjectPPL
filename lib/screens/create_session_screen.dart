import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_config.dart';
import '../services/firestore_service.dart';

class CreateSessionScreen extends StatefulWidget {
  final SessionConfig? existing;
  const CreateSessionScreen({super.key, this.existing});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _nameController = TextEditingController();
  int _sets = 3;
  int _workSeconds = 30;
  int _restSeconds = 10;
  String _cueType = 'all';
  bool _saving = false;

  // Work duration in minutes and seconds
  int _workMinutes = 0;
  int _workSecs = 30;
  // Rest duration in minutes and seconds
  int _restMinutes = 0;
  int _restSecs = 10;

  // Randomization range (in seconds)
  int _minGap = 3;
  int _maxGap = 8;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _sets = e.sets;
      _workMinutes = e.workSeconds ~/ 60;
      _workSecs = e.workSeconds % 60;
      _restMinutes = e.restSeconds ~/ 60;
      _restSecs = e.restSeconds % 60;
      _cueType = e.cueType;
      _minGap = e.minCueInterval;
      _maxGap = e.maxCueInterval;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a session name')));
      return;
    }
    
    // Validate randomization range
    if (_minGap >= _maxGap) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Min gap must be less than max gap')));
      return;
    }
    
    setState(() => _saving = true);
    _workSeconds = _workMinutes * 60 + _workSecs;
    _restSeconds = _restMinutes * 60 + _restSecs;
    
    final config = SessionConfig(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      sets: _sets,
      workSeconds: _workSeconds,
      restSeconds: _restSeconds,
      cueType: _cueType,
      userId: FirebaseAuth.instance.currentUser!.uid,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      minCueInterval: _minGap,
      maxCueInterval: _maxGap,
    );
    await FirestoreService().saveSessionConfig(config);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        title: Text(widget.existing == null ? 'New Session' : 'Edit Session'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Session Name'),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('e.g. HIIT Sprints'),
            ),
            const SizedBox(height: 24),
            _label('Number of Sets'),
            _stepper(_sets, (v) => setState(() => _sets = v), 1, 20),
            const SizedBox(height: 24),
            _label('Work Duration'),
            _dualTimeInput(
              minutes: _workMinutes,
              seconds: _workSecs,
              onMinutesChanged: (v) => setState(() => _workMinutes = v),
              onSecondsChanged: (v) => setState(() => _workSecs = v),
              label: 'Work',
            ),
            const SizedBox(height: 24),
            _label('Rest Duration'),
            _dualTimeInput(
              minutes: _restMinutes,
              seconds: _restSecs,
              onMinutesChanged: (v) => setState(() => _restMinutes = v),
              onSecondsChanged: (v) => setState(() => _restSecs = v),
              label: 'Rest',
            ),
            const SizedBox(height: 24),
            _label('Cue Type'),
            _cueSelector(),
            const SizedBox(height: 24),
            _label('Cue Randomization (Seconds)'),
            _randomizationRangeInput(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                    : const Text('Save Session',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00E5FF))),
      );

  Widget _stepper(int value, Function(int) onChanged, int min, int max) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white70),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text('$value',
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white70),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _dualTimeInput({
    required int minutes,
    required int seconds,
    required Function(int) onMinutesChanged,
    required Function(int) onSecondsChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Minutes',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    _timeCounter(
                      value: minutes,
                      onChanged: onMinutesChanged,
                      max: 59,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text('Seconds',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    _timeCounter(
                      value: seconds,
                      onChanged: onSecondsChanged,
                      max: 59,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total: ${minutes}m ${seconds}s',
            style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _timeCounter({
    required int value,
    required Function(int) onChanged,
    required int max,
  }) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: Color(0xFF00E5FF), size: 24),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
            ),
            child: Text(
              value.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline,
              color: Color(0xFF00E5FF), size: 24),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _cueSelector() {
    final options = [
      ('all', '⚡ All', 'Audio + Haptic + Visual'),
      ('audio', '🔔 Audio', 'Beep tone'),
      ('haptic', '📳 Haptic', 'Vibration'),
      ('visual', '💡 Visual', 'Screen flash'),
    ];
    return Column(
      children: options.map((opt) {
        final selected = _cueType == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _cueType = opt.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.1)
                  : const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? const Color(0xFF00E5FF) : Colors.white12),
            ),
            child: Row(
              children: [
                Text(opt.$1 == _cueType ? '◉ ' : '○ ',
                    style: TextStyle(
                        color: selected ? const Color(0xFF00E5FF) : Colors.white38)),
                Text(opt.$2,
                    style: TextStyle(
                        color: selected ? const Color(0xFF00E5FF) : Colors.white,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(opt.$3,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _randomizationRangeInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control when cues appear during work phases',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Min Gap',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _stepper(_minGap, (v) {
                      setState(() {
                        _minGap = v;
                        // Ensure max is always greater than min
                        if (_maxGap <= _minGap) {
                          _maxGap = _minGap + 1;
                        }
                      });
                    }, 1, 60),
                    const SizedBox(height: 4),
                    Text('Min time before cue',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max Gap',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _stepper(_maxGap, (v) {
                      setState(() {
                        _maxGap = v;
                        // Ensure min is always less than max
                        if (_minGap >= _maxGap) {
                          _minGap = _maxGap - 1;
                        }
                      });
                    }, 2, 60),
                    const SizedBox(height: 4),
                    Text('Max time before cue',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: const Color(0xFF00E5FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cues will appear randomly between ${_minGap}s and ${_maxGap}s apart',
                    style: const TextStyle(
                        color: Color(0xFF00E5FF), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}