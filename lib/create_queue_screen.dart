import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateQueueScreen extends StatefulWidget {
  const CreateQueueScreen({super.key});

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  int sets = 6;
  int workMinutes = 13;
  int workSeconds = 37;
  int restMinutes = 0;
  int restSeconds = 15;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _incrementSets() {
    setState(() {
      sets++;
    });
  }

  void _decrementSets() {
    if (sets > 1) {
      setState(() {
        sets--;
      });
    }
  }

  void _incrementWorkMinutes() {
    setState(() {
      workMinutes++;
    });
  }

  void _decrementWorkMinutes() {
    if (workMinutes > 0) {
      setState(() {
        workMinutes--;
      });
    }
  }

  void _incrementWorkSeconds() {
    setState(() {
      if (workSeconds >= 59) {
        workSeconds = 0;
        workMinutes++;
      } else {
        workSeconds++;
      }
    });
  }

  void _decrementWorkSeconds() {
    if (workSeconds > 0) {
      setState(() {
        workSeconds--;
      });
    } else if (workMinutes > 0) {
      setState(() {
        workSeconds = 59;
        workMinutes--;
      });
    }
  }

  void _incrementRestMinutes() {
    setState(() {
      restMinutes++;
    });
  }

  void _decrementRestMinutes() {
    if (restMinutes > 0) {
      setState(() {
        restMinutes--;
      });
    }
  }

  void _incrementRestSeconds() {
    setState(() {
      if (restSeconds >= 59) {
        restSeconds = 0;
        restMinutes++;
      } else {
        restSeconds++;
      }
    });
  }

  void _decrementRestSeconds() {
    if (restSeconds > 0) {
      setState(() {
        restSeconds--;
      });
    } else if (restMinutes > 0) {
      setState(() {
        restSeconds = 59;
        restMinutes--;
      });
    }
  }

  Future<void> _saveQueue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for this queue')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('queues').add({
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'sets': sets,
        'workMinutes': workMinutes,
        'workSeconds': workSeconds,
        'restMinutes': restMinutes,
        'restSeconds': restSeconds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving queue: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Queue'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Quickstart',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // SETS
            const Text('SETS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _decrementSets,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 40),
                Text(
                  '$sets',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 40),
                IconButton(
                  onPressed: _incrementSets,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // WORK
            const Text('WORK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _decrementWorkMinutes,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  '${workMinutes.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const Text(' : ', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                Text(
                  '${workSeconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _incrementWorkSeconds,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // REST
            const Text('REST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _decrementRestMinutes,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  '${restMinutes.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const Text(' : ', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                Text(
                  '${restSeconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _incrementRestSeconds,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Name input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Queue Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Basketball Practice',
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Save button
            ElevatedButton.icon(
              onPressed: _saveQueue,
              icon: const Icon(Icons.save),
              label: const Text('SAVE'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              'YOUR PRESETS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}