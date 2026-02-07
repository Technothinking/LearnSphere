import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chapter_selection_screen.dart';
import 'content_generation_screen.dart';
import 'revision_chapter_selection_screen.dart';

class HomeDashboard extends StatefulWidget {
  final VoidCallback? onNavigateToLearning;
  final String? subject;
  const HomeDashboard({super.key, this.onNavigateToLearning, this.subject});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  String _difficulty = "Loading...";
  double _mastery = 0.0;
  int _completedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentStatus();
  }

  Future<void> _fetchStudentStatus() async {
    final studentId = ApiService.currentUserId;
    if (studentId == null) {
      setState(() {
        _difficulty = "Please Login";
        _isLoading = false;
      });
      return;
    }

    // Load diagnostic/completion status
    try {
      final diagnostic = await ApiService.getDiagnosticStatus();
      if (mounted) {
        setState(() {
          _completedCount = (diagnostic['completed_chapters'] as List?)?.length ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching diagnostic count: $e');
    }

    // Retry mechanism to handle race conditions with profile setup
    int retries = 3;
    while (retries > 0) {
      try {
        final data = await ApiService.getNextAction();
        if (mounted) {
           setState(() {
             _difficulty = data['recommended_action']['difficulty'];
             _mastery = data['state_snapshot']['topic_mastery'];
             _isLoading = false;
           });
        }
        return; // Success
      } catch (e) {
        retries--;
        if (retries > 0) {
           await Future.delayed(const Duration(seconds: 1));
        } else {
           // Final fallback
           if (mounted) {
             setState(() {
               _difficulty = "Medium"; // Fallback
               _isLoading = false;
             });
           }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Adaptive Status Card
          _buildAdaptiveStatusCard(),
          const SizedBox(height: 12),
          _buildCompletionSummary(),
          const SizedBox(height: 24),
          
          Text(
            "Quick Navigation",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Main Section Cards
          _buildsectionCard(
            title: "Learning Modules",
            subtitle: "Continue your personalized path",
            icon: Icons.auto_stories,
            color: Colors.green.shade600,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChapterSelectionScreen(subject: widget.subject ?? "Science"),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildsectionCard(
            title: "Revision Tools",
            subtitle: "Strengthen your weak areas",
            icon: Icons.psychology,
            color: Colors.amber.shade700,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RevisionChapterSelectionScreen(subject: "Science"),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildsectionCard(
            title: "Support & Engagement",
            subtitle: "Chat with AI & view badges",
            icon: Icons.rocket_launch,
            color: Colors.blueGrey.shade600,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildsectionCard(
            title: "AI Content Lab",
            subtitle: "Generate questions from PDFs",
            icon: Icons.auto_awesome,
            color: Colors.deepPurpleAccent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ContentGenerationScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          // Weekly Performance removed as per request
        ],
      ),
    );
  }

  Widget _buildCompletionSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          const Text(
            "Chapter Tests Completed:",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          Text(
            "$_completedCount",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Current Mastery",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Difficulty: ${_difficulty.toUpperCase()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${(_mastery * 100).toInt()}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _mastery,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "AI is adapting your next lesson...",
            style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildsectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Dark slate
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }


}
