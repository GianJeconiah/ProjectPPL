import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/firestore_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _currentPage = 0;
  
  // User data
  int? _age;
  double? _weight;
  String _gender = 'prefer_not_to_say';
  String _goal = 'general_fitness';
  String _experienceLevel = 'beginner';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Save with timeout to prevent infinite loading
      await FirestoreService().saveUserProfile(userId, {
        'name': _nameController.text.trim(),
        'age': _age,
        'weight': _weight,
        'gender': _gender,
        'goal': _goal,
        'experienceLevel': _experienceLevel,
        'email': FirebaseAuth.instance.currentUser!.email,
        'onboardingCompleted': true,
        'createdAt': DateTime.now(),
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Firebase save operation timed out. Check your internet connection.');
        },
      );

      if (mounted) {
        setState(() => _saving = false);
        // The StreamBuilder in main.dart will automatically navigate to dashboard
        // No need to pop - just wait for the Firestore data to trigger the rebuild
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String errorMessage = e.toString();
        if (e is TimeoutException) {
          errorMessage = 'Connection timeout. Check your internet and try again.';
        } else if (errorMessage.contains('PERMISSION_DENIED')) {
          errorMessage = 'Permission denied. Check Firestore rules.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? const Color(0xFF00E5FF)
                            : Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildNamePage(),
                  _buildAgePage(),
                  _buildWeightGenderPage(),
                  _buildGoalPage(),
                  _buildExperiencePage(),
                ],
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage > 0 ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              _currentPage == 4 ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Color(0xFF00E5FF)),
          const SizedBox(height: 32),
          const Text(
            "What's your name?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "We'll use this to personalize your experience",
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: const Color(0xFF161B22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00E5FF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cake_outlined, size: 80, color: Color(0xFF00E5FF)),
          const SizedBox(height: 32),
          const Text(
            "How old are you?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "This helps us customize your training",
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _age != null && _age! > 13
                    ? () => setState(() => _age = _age! - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF00E5FF),
                iconSize: 40,
              ),
              const SizedBox(width: 32),
              Text(
                _age?.toString() ?? '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 32),
              IconButton(
                onPressed: _age == null || _age! < 100
                    ? () => setState(() => _age = (_age ?? 18) + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF00E5FF),
                iconSize: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightGenderPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.monitor_weight_outlined,
              size: 80, color: Color(0xFF00E5FF)),
          const SizedBox(height: 32),
          const Text(
            "Tell us about yourself",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          
          // Weight
          const Text(
            'Weight (kg)',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _weight != null && _weight! > 30
                    ? () => setState(() => _weight = _weight! - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF00E5FF),
                iconSize: 36,
              ),
              const SizedBox(width: 24),
              Text(
                _weight?.toStringAsFixed(0) ?? '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _weight == null || _weight! < 200
                    ? () => setState(() => _weight = (_weight ?? 70) + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF00E5FF),
                iconSize: 36,
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Gender
          const Text(
            'Gender',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _genderOption('Male', 'male', Icons.male),
              const SizedBox(width: 8),
              _genderOption('Female', 'female', Icons.female),
              const SizedBox(width: 8),
              _genderOption('Other', 'prefer_not_to_say', Icons.person),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderOption(String label, String value, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF00E5FF).withOpacity(0.15)
                : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF00E5FF) : Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFF00E5FF) : Colors.white38,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF00E5FF) : Colors.white70,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalPage() {
  return SingleChildScrollView(  // 
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events_outlined,
            size: 80, color: Color(0xFF00E5FF)),
        const SizedBox(height: 32),
        const Text(
          "What's your main goal?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        _goalOption('General Fitness', 'general_fitness',
            Icons.fitness_center, 'Stay active and healthy'),
        const SizedBox(height: 12),
        _goalOption('Build Strength', 'build_strength', Icons.trending_up,
            'Increase muscle and power'),
        const SizedBox(height: 12),
        _goalOption('Improve Endurance', 'improve_endurance',
            Icons.directions_run, 'Boost cardio capacity'),
        const SizedBox(height: 12),
        _goalOption('Sport Performance', 'sport_performance',
            Icons.sports_basketball, 'Excel at your sport'),
      ],
    ),
  );  
}

  Widget _goalOption(
      String label, String value, IconData icon, String subtitle) {
    final selected = _goal == value;
    return GestureDetector(
      onTap: () => setState(() => _goal = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00E5FF).withOpacity(0.15)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF00E5FF) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF00E5FF) : Colors.white38,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? const Color(0xFF00E5FF) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF00E5FF)),
          ],
        ),
      ),
    );
  }

  Widget _buildExperiencePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined,
              size: 80, color: Color(0xFF00E5FF)),
          const SizedBox(height: 32),
          const Text(
            "Training experience?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _experienceOption('Beginner', 'beginner',
              'Just getting started'),
          const SizedBox(height: 12),
          _experienceOption('Intermediate', 'intermediate',
              'Training regularly'),
          const SizedBox(height: 12),
          _experienceOption('Advanced', 'advanced',
              'Experienced athlete'),
        ],
      ),
    );
  }

  Widget _experienceOption(String label, String value, String subtitle) {
    final selected = _experienceLevel == value;
    return GestureDetector(
      onTap: () => setState(() => _experienceLevel = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00E5FF).withOpacity(0.15)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF00E5FF) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? const Color(0xFF00E5FF) : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF00E5FF)),
          ],
        ),
      ),
    );
  }
}