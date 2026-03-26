import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/session_log.dart';
import '../services/firestore_service.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final service = FirestoreService();

    return SafeArea(
      child: StreamBuilder<List<SessionLog>>(
        stream: service.getSessionLogs(userId),
        builder: (context, snap) {
          final logs = snap.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Performance',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${logs.length} sessions logged',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              if (logs.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart, size: 64, color: Colors.white12),
                        SizedBox(height: 16),
                        Text('No sessions yet',
                            style: TextStyle(color: Colors.white38, fontSize: 16)),
                        Text('Complete a session to see stats',
                            style: TextStyle(color: Colors.white24, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _buildStats(logs)),
                SliverToBoxAdapter(child: _buildChart(logs)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: const Text('Recent Sessions',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _SessionRow(log: logs[i]),
                    childCount: logs.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStats(List<SessionLog> logs) {
    final completed = logs.where((l) => l.completed).length;
    final totalSets = logs.fold(0, (s, l) => s + l.setsCompleted);
    final totalTime = logs.fold(0, (s, l) => s + l.durationSeconds);
    final avgDuration = logs.isEmpty ? 0 : totalTime ~/ logs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _statCard('Sessions', '$completed', Icons.check_circle_outline,
              const Color(0xFF00E5FF)),
          const SizedBox(width: 12),
          _statCard('Total Sets', '$totalSets', Icons.repeat,
              const Color(0xFF69FF47)),
          const SizedBox(width: 12),
          _statCard('Avg Time', _fmt(avgDuration), Icons.timer_outlined,
              const Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<SessionLog> logs) {
    final recent = logs.take(7).toList().reversed.toList();
    if (recent.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sets per Session (last 7)',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                backgroundColor: Colors.transparent,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= recent.length) return const SizedBox();
                        return Text(
                          DateFormat('M/d').format(recent[i].completedAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: recent
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.setsCompleted.toDouble(),
                              color: const Color(0xFF00E5FF),
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: recent
                                    .map((l) => l.setsCompleted)
                                    .reduce((a, b) => a > b ? a : b)
                                    .toDouble(),
                                color: Colors.white.withOpacity(0.04),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) {
    if (s < 60) return '${s}s';
    return '${s ~/ 60}m';
  }
}

class _SessionRow extends StatelessWidget {
  final SessionLog log;
  const _SessionRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(
            log.completed ? Icons.check_circle : Icons.cancel_outlined,
            color: log.completed ? const Color(0xFF69FF47) : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.sessionName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(DateFormat('MMM d, yyyy · h:mm a').format(log.completedAt),
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${log.setsCompleted}/${log.totalSets} sets',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(_fmtDur(log.durationSeconds),
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDur(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final r = s % 60;
    return r == 0 ? '${m}m' : '${m}m ${r}s';
  }
}