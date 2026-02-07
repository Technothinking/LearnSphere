import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'quiz_player_screen.dart';

class SubjectQuizScreen extends StatefulWidget {
  const SubjectQuizScreen({super.key});

  @override
  State<SubjectQuizScreen> createState() => _SubjectQuizScreenState();

  static void _showStartDialog(BuildContext context, String subject) async {
    final studentId = ApiService.currentUserId;
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start a quiz.')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch adaptive recommendation from RL backend
      final recommendation = await ApiService.getNextAction();
      final action = recommendation['recommended_action'];

      // Close loading indicators
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text('AI Recommendation for $subject'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Based on your previous performance, the RL Agent (PPO) suggests:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action['label'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(
                              'Difficulty: ${action['difficulty'].toUpperCase()} • Mode: ${action['mode']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This path is optimized to maximize your learning reward and topic mastery.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Change Path'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuizPlayerScreen(
                        difficulty: action['difficulty'],
                        subject: subject,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text('Accept & Start'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // close loader
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to AI backend: $e')),
        );
      }
    }
  }
}

class _SubjectQuizScreenState extends State<SubjectQuizScreen> {
  List<String>? _subjects;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final subs = await ApiService.getSubjects();
      if (mounted) {
        setState(() {
          _subjects = subs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects — QuickLearn'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: _DummySearchDelegate());
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        child: Icon(Icons.school, size: 30),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose a Subject',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Pick a subject to see quizzes and start an interactive session.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_subjects == null || _subjects!.isEmpty)
                        ? const Center(child: Text("No subjects available yet"))
                        : GridView.builder(
                            itemCount: _subjects!.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) {
                              final title = _subjects![index];
                              return _SubjectCard(
                                title: title,
                                color: Colors.indigo,
                                progress: 0.0,
                                quizzes: 0,
                                onStart: () => SubjectQuizScreen._showStartDialog(context, title),
                                onDetails: () {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Details for $title coming soon!')),
                                  );
                                },
                              );
                            },
                          ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String title;
  final Color color;
  final double progress;
  final int quizzes;
  final VoidCallback onStart;
  final VoidCallback onDetails;

  const _SubjectCard({
    required this.title,
    required this.color,
    required this.progress,
    required this.quizzes,
    required this.onStart,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onDetails,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color,
                    child: Text(
                      title[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onDetails,
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DummySearchDelegate extends SearchDelegate<String> {
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, ''),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildSuggestions(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16.0),
    child: Text('Search UI (placeholder)'),
  );

  @override
  Widget buildResults(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16.0),
    child: Text('No results — UI only'),
  );

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
}
