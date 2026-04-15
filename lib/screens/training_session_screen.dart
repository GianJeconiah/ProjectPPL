import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_config.dart';
import '../models/session_log.dart';
import '../services/cue_service.dart';
import '../services/firestore_service.dart';

enum SessionPhase { idle, work, rest, complete }

class TrainingSessionScreen extends StatefulWidget {
  final SessionConfig config;
  const TrainingSessionScreen({super.key, required this.config});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen>
    with TickerProviderStateMixin {
  late int _secondsLeft;
  int _currentSet = 1;

  /// Tracks how many sets have been fully completed (work phase finished).
  int _setsCompleted = 0;

  SessionPhase _phase = SessionPhase.idle;
  Timer? _timer;
  Timer? _cueTimer;

  // ── Directional cue state ─────────────────────────────────────────────────
  bool _showCueFlash = false;
  CueDirection? _cueDirection; // null = non-directional flash

  bool _paused = false;
  int _totalElapsed = 0;
  final _cueService = CueService();
  final _firestoreService = FirestoreService();
  late AnimationController _pulseController;
  late AnimationController _flashController;
  late AnimationController _arrowScaleController;
  final _random = Random();

  // All four directions to cycle through randomly
  static const _directions = CueDirection.values;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.config.workSeconds;
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _flashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _arrowScaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _arrowScaleController.reverse();
        }
      });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cueTimer?.cancel();
    _pulseController.dispose();
    _flashController.dispose();
    _arrowScaleController.dispose();
    _cueService.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Session control ───────────────────────────────────────────────────────

  void _start() {
    setState(() {
      _phase = SessionPhase.work;
      _secondsLeft = widget.config.workSeconds;
      _currentSet = 1;
      _setsCompleted = 0;
      _paused = false;
    });
    _startTimer();
    _scheduleRandomCue();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() {
        _totalElapsed++;
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) _onPhaseComplete();
    });
  }

  void _onPhaseComplete() {
    _cueTimer?.cancel();
    if (_phase == SessionPhase.work) {
      _setsCompleted++;
      if (_currentSet >= widget.config.sets) {
        _completeSession();
      } else {
        _triggerCue();
        setState(() {
          _phase = SessionPhase.rest;
          _secondsLeft = widget.config.restSeconds;
        });
      }
    } else if (_phase == SessionPhase.rest) {
      _triggerCue();
      setState(() {
        _currentSet++;
        _phase = SessionPhase.work;
        _secondsLeft = widget.config.workSeconds;
      });
      _scheduleRandomCue();
    }
  }

  void _scheduleRandomCue() {
    _cueTimer?.cancel();
    final min = widget.config.minCueInterval;
    final max = widget.config.maxCueInterval;
    if (min >= max) return;
    final delay = min + _random.nextInt(max - min);
    _cueTimer = Timer(Duration(seconds: delay), () {
      if (!mounted || _phase != SessionPhase.work || _paused) return;
      _triggerCue();
      _scheduleRandomCue(); // reschedule for the next cue within this set
    });
  }

  // ── Directional cue logic ─────────────────────────────────────────────────

  /// Pick a random direction (null = non-directional, for rest/phase transitions).
  CueDirection _randomDirection() =>
      _directions[_random.nextInt(_directions.length)];

  void _triggerCue({bool directional = true}) {
    // During work phase mid-set cues → use directional arrows.
    // During phase transitions (rest ↔ work) → plain flash, no arrow.
    final dir = (directional && _phase == SessionPhase.work)
        ? _randomDirection()
        : null;

    if (widget.config.cueType == 'visual' ||
        widget.config.cueType == 'all') {
      setState(() {
        _showCueFlash = true;
        _cueDirection = dir;
      });
      _flashController.forward(from: 0);
      _arrowScaleController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _showCueFlash = false;
            _cueDirection = null;
          });
        }
      });
    }

    _cueService.triggerCue(widget.config.cueType, direction: dir);
  }

  void _togglePause() => setState(() => _paused = !_paused);

  void _stop() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Stop Session?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Your progress will be saved.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue',
                  style: TextStyle(color: Color(0xFF00E5FF)))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _completeSession(stopped: true);
              },
              child: const Text('Stop',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Future<void> _completeSession({bool stopped = false}) async {
    _timer?.cancel();
    _cueTimer?.cancel();
    setState(() => _phase = SessionPhase.complete);

    final log = SessionLog(
      id: '',
      userId: FirebaseAuth.instance.currentUser!.uid,
      sessionName: widget.config.name,
      setsCompleted: stopped ? _setsCompleted : widget.config.sets,
      totalSets: widget.config.sets,
      durationSeconds: _totalElapsed,
      completedAt: DateTime.now(),
      completed: !stopped,
    );
    await _firestoreService.saveSessionLog(log);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _phaseColor {
    switch (_phase) {
      case SessionPhase.work:
        return const Color(0xFF00E5FF);
      case SessionPhase.rest:
        return const Color(0xFF69FF47);
      case SessionPhase.complete:
        return const Color(0xFFFFD700);
      default:
        return Colors.white54;
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case SessionPhase.work:
        return 'WORK';
      case SessionPhase.rest:
        return 'REST';
      case SessionPhase.complete:
        return 'DONE!';
      default:
        return 'READY';
    }
  }

  // ── Directional arrow widget ──────────────────────────────────────────────

  static const _directionIcons = {
    CueDirection.up: Icons.arrow_upward_rounded,
    CueDirection.down: Icons.arrow_downward_rounded,
    CueDirection.left: Icons.arrow_back_rounded,
    CueDirection.right: Icons.arrow_forward_rounded,
  };

  static const _directionLabels = {
    CueDirection.up: 'UP',
    CueDirection.down: 'DOWN',
    CueDirection.left: 'LEFT',
    CueDirection.right: 'RIGHT',
  };

  Widget _buildDirectionalArrow(CueDirection direction, Color color) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _arrowScaleController, curve: Curves.elasticOut),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.6), width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(
              _directionIcons[direction]!,
              color: color,
              size: 80,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _directionLabels[direction]!,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _showCueFlash
          ? _phaseColor.withOpacity(0.3)
          : const Color(0xFF0D1117),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _showCueFlash
            ? _phaseColor.withOpacity(0.25)
            : Colors.transparent,
        child: SafeArea(
          child: _phase == SessionPhase.complete
              ? _buildCompleteView()
              : _phase == SessionPhase.idle
                  ? _buildIdleView()
                  : _buildTimerView(),
        ),
      ),
    );
  }

  Widget _buildIdleView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined,
              size: 80, color: Color(0xFF00E5FF)),
          const SizedBox(height: 24),
          Text(widget.config.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            '${widget.config.sets} sets · ${_formatTime(widget.config.workSeconds)} work · ${_formatTime(widget.config.restSeconds)} rest',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: _start,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5)
                ],
              ),
              child:
                  const Icon(Icons.play_arrow, size: 56, color: Colors.black),
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back',
                style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerView() {
    final progress = _phase == SessionPhase.work
        ? _secondsLeft / widget.config.workSeconds
        : _secondsLeft / widget.config.restSeconds;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Set $_currentSet of ${widget.config.sets}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 16)),
                  Text(widget.config.name,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.config.sets, (i) {
                final done = i < _currentSet - 1;
                final current = i == _currentSet - 1;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: current ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: done
                        ? _phaseColor
                        : current
                            ? _phaseColor
                            : Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const Spacer(),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                  color: _phaseColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6),
              child: Text(_phaseLabel),
            ),
            const SizedBox(height: 16),
            // Timer ring
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(_phaseColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(_secondsLeft),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 2),
                      ),
                      if (_paused)
                        const Text('PAUSED',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                letterSpacing: 4)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                      icon: Icons.stop,
                      color: Colors.redAccent,
                      onTap: _stop),
                  _bigPlayButton(),
                  _controlButton(
                      icon: Icons.skip_next,
                      color: Colors.white38,
                      onTap: _onPhaseComplete),
                ],
              ),
            ),
          ],
        ),

        // ── Directional cue overlay ─────────────────────────────────────────
        if (_showCueFlash)
          Positioned.fill(
            child: Container(color: _phaseColor.withOpacity(0.15)),
          ),
        if (_showCueFlash && _cueDirection != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: _buildDirectionalArrow(_cueDirection!, _phaseColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bigPlayButton() {
    return GestureDetector(
      onTap: _togglePause,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) => Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _phaseColor,
            boxShadow: [
              BoxShadow(
                  color: _phaseColor
                      .withOpacity(0.3 + 0.2 * _pulseController.value),
                  blurRadius: 20 + 10 * _pulseController.value,
                  spreadRadius: 2)
            ],
          ),
          child: Icon(_paused ? Icons.play_arrow : Icons.pause,
              size: 36, color: Colors.black),
        ),
      ),
    );
  }

  Widget _controlButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildCompleteView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          const Text('Session Complete!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
              '${widget.config.sets} sets · ${_formatTime(_totalElapsed)} total',
              style: const TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Back to Dashboard',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}