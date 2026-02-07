import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/onboarding_screen.dart';
import 'screens/Dashboard.dart';
import 'screens/setup_after_login.dart';
import 'services/api_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _needsSetup = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  void _initAuth() {
    // Listen to Auth State Changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _checkUserSetup();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _needsSetup = false; // Reset
          });
        }
      }
    });
  }

  Future<void> _checkUserSetup() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Check if user has completed setup/diagnostic
      final status = await ApiService.getDiagnosticStatus();
      
      // If needs_diagnostic is true, it means they haven't finished setup
      // If needs_diagnostic is false (or API fails safely), assume setup done
      final needsDiagnostic = status['needs_diagnostic'] ?? true;
      final hasGrade = status['has_grade'] ?? false;

      if (mounted) {
        setState(() {
          // Setup is only needed if they have no grade AND need diagnostic.
          // Or more simply: if they have a grade, they have passed setup.
          _needsSetup = !hasGrade; 
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error checking setup status: $e");
      // Fallback: If error, assume needs setup to be safe, or dashboard?
      // Let's assume dashboard to avoid blocking if API is down, 
      // but "needsSetup=true" is safer for data integrity.
      if (mounted) {
        setState(() {
          _needsSetup = true; 
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = Supabase.instance.client.auth.currentSession;

    // 1. Not Logged In -> Onboarding
    if (session == null) {
      return const OnboardingScreen();
    }

    // 2. Logged In but Needs Setup -> Setup Screen
    if (_needsSetup) {
      return const CreativeSetupAfterLoginV2();
    }

    // 3. Logged In & Setup Complete -> Dashboard
    return const DashboardScreen();
  }
}
