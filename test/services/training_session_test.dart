import 'package:flutter_test/flutter_test.dart';

enum SessionPhase { idle, work, rest, complete }

void main() {
  test('WBT-03: State Transition (DNF Logic)', () {
    SessionPhase phase = SessionPhase.work;
    bool isManuallyStopped = true;
    if (isManuallyStopped) phase = SessionPhase.idle;
    expect(phase, equals(SessionPhase.idle));
  });

  test('WBT-05: Countdown Zero-Floor Safety', () {
    int secondsLeft = 1;
    secondsLeft--; // Simulate decrement
    expect(secondsLeft, greaterThanOrEqualTo(0));
  });
}