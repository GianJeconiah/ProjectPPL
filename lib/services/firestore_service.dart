import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_config.dart';
import '../models/session_log.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Session configs
  Stream<List<SessionConfig>> getSessionConfigs(String userId) {
    print('🔵 Fetching sessions for userId: $userId');
    return _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          print('📊 Found ${snap.docs.length} sessions');
          // Sort client-side instead of in Firestore
          final sessions = snap.docs
              .map((d) {
                print('Session: ${d.data()}');
                return SessionConfig.fromMap(d.data(), d.id);
              })
              .toList();
          sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sessions;
        });
  }

  Future<void> saveSessionConfig(SessionConfig config) async {
    try {
      print('🔵 Saving session config: ${config.name} for userId: ${config.userId}');
      if (config.id.isEmpty) {
        await _db.collection('sessions').add(config.toMap());
        print('✅ Session created successfully');
      } else {
        await _db.collection('sessions').doc(config.id).set(config.toMap());
        print('✅ Session updated successfully');
      }
    } catch (e) {
      print('❌ Error saving session: $e');
      rethrow;
    }
  }

  Future<void> deleteSessionConfig(String id) async {
    await _db.collection('sessions').doc(id).delete();
  }

  // Session logs
  Stream<List<SessionLog>> getSessionLogs(String userId) {
    print('🔵 Fetching session logs for userId: $userId');
    return _db
        .collection('session_logs')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          print('📊 Found ${snap.docs.length} session logs');
          // Sort client-side instead of in Firestore
          final logs = snap.docs
              .map((d) {
                print('Log: ${d.data()}');
                return SessionLog.fromMap(d.data(), d.id);
              })
              .toList();
          logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
          return logs.take(30).toList();
        });
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
    try {
      print('🔵 Saving user profile for $userId...');
      print('📊 Data: $data');
      await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
      print('✅ User profile saved successfully');
    } catch (e) {
      print('❌ Error saving user profile: $e');
      rethrow;
    }
  }
}