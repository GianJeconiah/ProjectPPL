import 'package:cloud_firestore/cloud_firestore.dart';

class SessionConfig {
  final String id;
  final String name;
  final int sets;
  final int workSeconds;
  final int restSeconds;
  final String cueType; // 'audio', 'visual', 'haptic', 'all'
  final String userId;
  final DateTime createdAt;

  SessionConfig({
    required this.id,
    required this.name,
    required this.sets,
    required this.workSeconds,
    required this.restSeconds,
    required this.cueType,
    required this.userId,
    required this.createdAt,
  });

  factory SessionConfig.fromMap(Map<String, dynamic> map, String id) {
    return SessionConfig(
      id: id,
      name: map['name'] ?? '',
      sets: map['sets'] ?? 1,
      workSeconds: map['workSeconds'] ?? 30,
      restSeconds: map['restSeconds'] ?? 10,
      cueType: map['cueType'] ?? 'all',
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets,
        'workSeconds': workSeconds,
        'restSeconds': restSeconds,
        'cueType': cueType,
        'userId': userId,
        // Use Firestore Timestamp — writing a raw DateTime throws an error.
        'createdAt': Timestamp.fromDate(createdAt),
      };
}