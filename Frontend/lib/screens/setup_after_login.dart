import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'Dashboard.dart';

// Premium-styled, refined CreativeSetupAfterLogin (v2)
// - cleaner layout, improved typography, gold accent palette
// - animated, elevated interactive chips and preview
// - responsive width, subtle motion and better spacing

class CreativeSetupAfterLoginV2 extends StatefulWidget {
  const CreativeSetupAfterLoginV2({super.key});

  @override
  State<CreativeSetupAfterLoginV2> createState() =>
      _CreativeSetupAfterLoginV2State();
}

class _CreativeSetupAfterLoginV2State extends State<CreativeSetupAfterLoginV2>
    with SingleTickerProviderStateMixin {
  String? _selectedBoard = 'State Board'; // Default to State Board
  String? _selectedClass = '9'; // Default to grade 9
  final List<String> _boards = ['State Board']; // Only State Board
  final List<String> _classes = ['9']; // Only grade 9
  final List<String> _allSubjects = ['Science']; // Only Science
  final Set<String> _selectedSubjects = {};

  late final AnimationController _entranceController;
  late final Animation<double> _fade;

  static const Color _navy = Color(0xFF0F172A);
  static const Color _teal = Color(0xFF1E293B);
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _card = Color(0xFF1E293B);
  static const double _radius = 14.0;

  @override
  void initState() {
    super.initState();
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Faster animation
    );
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _toggleSubject(String s) => setState(
    () =>
        _selectedSubjects.contains(s)
            ? _selectedSubjects.remove(s)
            : _selectedSubjects.add(s),
  );

  void _saveAndContinue() async {
    if (_selectedBoard == null || _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose board & class')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final grade = int.tryParse(_selectedClass!) ?? 10;
      // Increased timeout slightly but keep it resilient.
      await ApiService.setupStudentProfile(grade).timeout(
        const Duration(seconds: 5), 
        onTimeout: () {
          print("Setup profile taking longer than expected, proceeding...");
        }
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loader
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      print("ERROR during setup: $e");
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile setup partially failed: $e. You can continue to dashboard.')),
        );
        // Still allow navigation to dashboard if setup fails (they are authenticated anyway)
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        });
      }
    }
  }

  Widget _boardButton(String b) {
    final sel = b == _selectedBoard;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient:
            sel
                ? const LinearGradient(colors: [_blue, Color(0xFF2563EB)])
                : null,
        color: sel ? null : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        boxShadow:
            sel
                ? [
                  BoxShadow(
                    color: _blue.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ]
                : null,
      ),
      child: InkWell(
        onTap:
            () => setState(() {
              final was = _selectedBoard == b;
              _selectedBoard = was ? null : b;
            }),
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sel ? Icons.star : Icons.school,
              color: sel ? Colors.black87 : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              b,
              style: TextStyle(
                color: sel ? Colors.black87 : Colors.white70,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectChip(String s) {
    final sel = _selectedSubjects.contains(s);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sel ? _blue.withOpacity(0.12) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sel ? _blue.withOpacity(0.8) : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleSubject(s),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sel)
              const Icon(Icons.check, size: 16, color: _blue)
            else
              const SizedBox.shrink(),
            if (sel) const SizedBox(width: 6),
            Text(
              s,
              style: TextStyle(
                color: sel ? _blue : Colors.white70,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewCard() {
    final board = _selectedBoard ?? '—';
    final cls = _selectedClass ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [_blue, Color(0xFF2563EB)],
              ),
            ),
            child: const Icon(Icons.menu_book, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Board: $board',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Class: $cls • Subjects: Auto',
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.withOpacity(0.14),
            child: const Icon(Icons.check, color: Colors.green),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: _navy,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // subtle background texture
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_navy, _teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // rounded header
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_blue, Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.person, color: _blue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome!',
                            style: TextStyle(color: Colors.black87),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Customize your learning',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const DashboardScreen(),
                            ),
                          ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 120, 18, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 820 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // main card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(_radius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Choose your board',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                children:
                                    _boards
                                        .map((b) => _boardButton(b))
                                        .toList(),
                              ),

                              const SizedBox(height: 18),
                              const Text(
                                'Select your class',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedClass,
                                  isExpanded: true,
                                  underline: const SizedBox.shrink(),
                                  hint: const Text('Choose class'),
                                  items:
                                      _classes
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text('Class $c'),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (v) => setState(() => _selectedClass = v),
                                ),
                              ),

                              const SizedBox(height: 18),
                              const Text(
                                'Pick subjects you want to focus on',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Subjects will be loaded automatically from your curriculum.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),

                              const SizedBox(height: 18),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                child: _previewCard(),
                              ),

                              const SizedBox(height: 16),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _saveAndContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.black87,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Save & Continue',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const DashboardScreen(),
                                      ),
                                    ),
                                child: const Text(
                                  'Skip for now',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.lightbulb, color: _blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tip: You can change board & class later in settings. We pick sensible subjects automatically if you skip.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
