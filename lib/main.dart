import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CueWatchApp());
}

class CueWatchApp extends StatelessWidget {
  const CueWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CueWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E5FF),
          surface: const Color(0xFF161B22),
          background: const Color(0xFF0D1117),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0D1117),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              ),
            );
          }
          
          if (snap.hasData) {
            // User is logged in, check if onboarding is completed using StreamBuilder
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snap.data!.uid)
                  .snapshots(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Color(0xFF0D1117),
                    body: Center(
                      child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    ),
                  );
                }
                
                // Check if user has completed onboarding
                final userData = userSnap.data?.data() as Map<String, dynamic>?;
                final onboardingCompleted = userData?['onboardingCompleted'] == true;
                
                if (onboardingCompleted) {
                  return const DashboardScreen();
                } else {
                  return const OnboardingScreen();
                }
              },
            );
          }
          
          return const AuthScreen();
        },
      ),
    );
  }
}