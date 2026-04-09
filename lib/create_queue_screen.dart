import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_config.dart';
import '../services/firestore_service.dart';

class CreateQueueScreen extends StatefulWidget {
  const CreateQueueScreen({super.key});

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  int _sets = 6;
  int _workMinutes = 13;
  int _workSeconds = 37;
  int _restMinutes = 0;
  int _restSeconds = 15;
  final _nameController = TextEditingController();
  final _firestoreService = FirestoreService();

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Sets ──────────────────────────────────────────────────────────────────
  void _incrementSets() => setState(() => _sets++);
  void _decrementSets() {
    if (_sets > 1) setState(() => _sets--);
  }

  // ── Work minutes ──────────────────────────────────────────────────────────
  void _incrementWorkMinutes() => setState(() => _workMinutes++);
  void _decrementWorkMinutes() {
    if (_workMinutes > 0) setState(() => _workMinutes--);
  }

  // ── Work seconds ──────────────────────────────────────────────────────────
  void _incrementWorkSeconds() {
    setState(() {
      if (_workSeconds >= 59) {
        _workSeconds = 0;
        _workMinutes++;
      } else {
        _workSeconds++;
      }
    });
  }

  void _decrementWorkSeconds() {
    setState(() {
      if (_workSeconds > 0) {
        _workSeconds--;
      } else if (_workMinutes > 0) {
        _workSeconds = 59;
        _workMinutes--;
      }
    });
  }

  // ── Rest minutes ──────────────────────────────────────────────────────────
  void _incrementRestMinutes() => setState(() => _restMinutes++);
  void _decrementRestMinutes() {
    if (_restMinutes > 0) setState(() => _restMinutes--);
  }

  // ── Rest seconds ──────────────────────────────────────────────────────────
  void _incrementRestSeconds() {
    setState(() {
      if (_restSeconds >= 59) {
        _restSeconds = 0;
        _restMinutes++;
      } else {
        _restSeconds++;
      }
    });
  }

  void _decrementRestSeconds() {
    setState(() {
      if (_restSeconds > 0) {
        _restSeconds--;
      } else if (_restMinutes > 0) {
        _restSeconds = 59;
        _restMinutes--;
      }
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _saveQueue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for this queue')),
      );
      return;
    }

    final config = SessionConfig(
      id: '',
      name: _nameController.text.trim(),
      sets: _sets,
      workSeconds: _workMinutes * 60 + _workSeconds,
      restSeconds: _restMinutes * 60 + _restSeconds,
      cueType: 'all',
      userId: _userId,
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.saveSessionConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue saved!')),
        );
        _nameController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving queue: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        title: const Text('Create Queue'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Quickstart',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 40),

            // ── SETS ────────────────────────────────────────────────────────
            _sectionLabel('SETS'),
            const SizedBox(height: 16),
            _counterRow(
              value: '$_sets',
              onDecrement: _decrementSets,
              onIncrement: _incrementSets,
            ),

            const SizedBox(height: 40),

            // ── WORK ────────────────────────────────────────────────────────
            _sectionLabel('WORK'),
            const SizedBox(height: 16),
            _dualCounterRow(
              minutesValue: _workMinutes,
              secondsValue: _workSeconds,
              onDecrementMinutes: _decrementWorkMinutes,
              onIncrementMinutes: _incrementWorkMinutes,
              onDecrementSeconds: _decrementWorkSeconds,
              onIncrementSeconds: _incrementWorkSeconds,
            ),

            const SizedBox(height: 40),

            // ── REST ────────────────────────────────────────────────────────
            _sectionLabel('REST'),
            const SizedBox(height: 16),
            _dualCounterRow(
              minutesValue: _restMinutes,
              secondsValue: _restSeconds,
              onDecrementMinutes: _decrementRestMinutes,
              onIncrementMinutes: _incrementRestMinutes,
              onDecrementSeconds: _decrementRestSeconds,
              onIncrementSeconds: _incrementRestSeconds,
            ),

            const SizedBox(height: 40),

            // ── Name input ──────────────────────────────────────────────────
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Queue Name',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'e.g., Basketball Practice',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF00E5FF)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Save button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveQueue,
                icon: const Icon(Icons.save),
                label: const Text('SAVE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Presets list ────────────────────────────────────────────────
            const Text(
              'YOUR PRESETS',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<SessionConfig>>(
              stream: _firestoreService.getSessionConfigs(_userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                      color: Color(0xFF00E5FF));
                }
                final presets = snap.data ?? [];
                if (presets.isEmpty) {
                  return const Text(
                    'No presets saved yet.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: presets.length,
                  itemBuilder: (context, i) {
                    final p = presets[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  '${p.sets} sets · ${p.workSeconds}s work · ${p.restSeconds}s rest',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.white24, size: 20),
                            onPressed: () =>
                                _firestoreService.deleteSessionConfig(p.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 2),
      );

  Widget _iconBtn(VoidCallback onTap, IconData icon) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );

  /// Single-number counter (used for SETS).
  Widget _counterRow({
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconBtn(onDecrement, Icons.remove),
        const SizedBox(width: 40),
        Text(value,
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(width: 40),
        _iconBtn(onIncrement, Icons.add),
      ],
    );
  }

  /// MM:SS counter with independent +/- for minutes AND seconds.
  Widget _dualCounterRow({
    required int minutesValue,
    required int secondsValue,
    required VoidCallback onDecrementMinutes,
    required VoidCallback onIncrementMinutes,
    required VoidCallback onDecrementSeconds,
    required VoidCallback onIncrementSeconds,
  }) {
    final mm = minutesValue.toString().padLeft(2, '0');
    final ss = secondsValue.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Minutes column
        Column(
          children: [
            _iconBtn(onIncrementMinutes, Icons.add),
            const SizedBox(height: 8),
            Text(mm,
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            _iconBtn(onDecrementMinutes, Icons.remove),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(':',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54)),
        ),
        // Seconds column
        Column(
          children: [
            _iconBtn(onIncrementSeconds, Icons.add),
            const SizedBox(height: 8),
            Text(ss,
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            _iconBtn(onDecrementSeconds, Icons.remove),
          ],
        ),
      ],
    );
  }
}