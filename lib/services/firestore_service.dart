import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_config.dart';
import '../models/session_log.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Session configs
  Stream<List<SessionConfig>> getSessionConfigs(String userId) {
    return _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SessionConfig.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> saveSessionConfig(SessionConfig config) async {
    if (config.id.isEmpty) {
      await _db.collection('sessions').add(config.toMap());
    } else {
      await _db.collection('sessions').doc(config.id).set(config.toMap());
    }
  }

  Future<void> deleteSessionConfig(String id) async {
    await _db.collection('sessions').doc(id).delete();
  }

  // Session logs
  Stream<List<SessionLog>> getSessionLogs(String userId) {
    return _db
        .collection('session_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SessionLog.fromMap(d.data(), d.id)).toList());
  }

  Future<void> saveSessionLog(SessionLog log) async {
    await _db.collection('session_logs').add(log.toMap());
  }

  // User profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> saveUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }
}