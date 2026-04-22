import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_config.dart';
import '../services/firestore_service.dart';
import 'training_session_screen.dart';
import 'create_session_screen.dart';
import 'performance_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final _firestoreService = FirestoreService();

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(userId: _userId, firestoreService: _firestoreService),
      const PerformanceScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF161B22),
        indicatorColor: const Color(0xFF00E5FF).withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF00E5FF)),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF00E5FF)),
              label: 'Performance'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF00E5FF)),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userId;
  final FirestoreService firestoreService;

  const _HomeTab({required this.userId, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CueWatch',
                        style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 13,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Good ${_greeting()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF00E5FF), size: 32),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreateSessionScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Your training sessions',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<SessionConfig>>(
              stream: firestoreService.getSessionConfigs(userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                }
                
                // Check for errors
                if (snap.hasError) {
                  print('❌ StreamBuilder Error: ${snap.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading sessions: ${snap.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  );
                }
                
                final sessions = snap.data ?? [];
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 64, color: Colors.white12),
                        const SizedBox(height: 16),
                        const Text('No sessions yet',
                            style: TextStyle(color: Colors.white38, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Tap + to create your first session',
                            style: TextStyle(color: Colors.white24, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) =>
                      _SessionCard(session: sessions[i], firestoreService: firestoreService),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _SessionCard extends StatelessWidget {
  final SessionConfig session;
  final FirestoreService firestoreService;

  const _SessionCard({required this.session, required this.firestoreService});

  String _cueIcon(String type) {
    switch (type) {
      case 'audio': return '🔔';
      case 'haptic': return '📳';
      case 'visual': return '💡';
      default: return '⚡';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.timer, color: Color(0xFF00E5FF)),
        ),
        title: Text(session.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${session.sets} sets · ${session.workSeconds}s work · ${session.restSeconds}s rest · ${_cueIcon(session.cueType)}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white38, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateSessionScreen(existing: session)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
              onPressed: () => _confirmDelete(context),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TrainingSessionScreen(config: session)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Start',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Delete Session', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${session.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () {
                firestoreService.deleteSessionConfig(session.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}