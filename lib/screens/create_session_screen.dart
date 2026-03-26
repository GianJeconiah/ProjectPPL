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

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _sets = e.sets;
      _workSeconds = e.workSeconds;
      _restSeconds = e.restSeconds;
      _cueType = e.cueType;
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a session name')));
      return;
    }
    setState(() => _saving = true);
    final config = SessionConfig(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      sets: _sets,
      workSeconds: _workSeconds,
      restSeconds: _restSeconds,
      cueType: _cueType,
      userId: FirebaseAuth.instance.currentUser!.uid,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
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
            _timeSelector(_workSeconds, (v) => setState(() => _workSeconds = v)),
            const SizedBox(height: 24),
            _label('Rest Duration'),
            _timeSelector(_restSeconds, (v) => setState(() => _restSeconds = v)),
            const SizedBox(height: 24),
            _label('Cue Type'),
            _cueSelector(),
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

  Widget _timeSelector(int seconds, Function(int) onChanged) {
    final options = [10, 15, 20, 30, 45, 60, 90, 120, 180, 300];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((s) {
        final selected = s == seconds;
        final label = s >= 60 ? '${s ~/ 60}m' : '${s}s';
        return GestureDetector(
          onTap: () => onChanged(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF00E5FF) : const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? const Color(0xFF00E5FF) : Colors.white12),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ),
        );
      }).toList(),
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
                  ? const Color(0xFF00E5FF).withOpacity(0.1)
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
}