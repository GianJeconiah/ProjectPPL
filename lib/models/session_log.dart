import 'package:cloud_firestore/cloud_firestore.dart';

class SessionLog {
  final String id;
  final String userId;
  final String sessionName;
  final int setsCompleted;
  final int totalSets;
  final int durationSeconds;
  final DateTime completedAt;
  final bool completed;

  SessionLog({
    required this.id,
    required this.userId,
    required this.sessionName,
    required this.setsCompleted,
    required this.totalSets,
    required this.durationSeconds,
    required this.completedAt,
    required this.completed,
  });

  factory SessionLog.fromMap(Map<String, dynamic> map, String id) {
    return SessionLog(
      id: id,
      userId: map['userId'] ?? '',
      sessionName: map['sessionName'] ?? '',
      setsCompleted: map['setsCompleted'] ?? 0,
      totalSets: map['totalSets'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 0,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: map['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'sessionName': sessionName,
        'setsCompleted': setsCompleted,
        'totalSets': totalSets,
        'durationSeconds': durationSeconds,
        'completedAt': Timestamp.fromDate(completedAt),
        'completed': completed,
      };
}