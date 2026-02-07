import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'Dashboard.dart';

class QuizPlayerScreen extends StatefulWidget {
  final String? difficulty; // Optional now for adaptive
  final String subject;
  final String? chapter;
  final String? topic;
  final bool isCommonTest;

  const QuizPlayerScreen({
    super.key,
    this.difficulty,
    required this.subject,
    this.chapter,
    this.topic,
    this.isCommonTest = false,
  });

  @override
  State<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<QuizPlayerScreen> {
  List<dynamic>? _questions;
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isExiting = false;
  String? _errorMessage;
  String? _resolvedDifficulty; // Track actual difficulty for display/RL
  DateTime? _startTime;
  DateTime? _questionStartTime; // Track time for the current question
  Timer? _timer;
  int _remainingSeconds = 0;

  final Map<int, int> _selectedAnswers = {};
  final Map<int, String> _textAnswers = {};
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _answers = []; // Track correct/incorrect for each question

  @override
  void initState() {
    super.initState();
    _resolvedDifficulty = widget.difficulty; 
    
    // Proactively show intro if Common Test
    if (widget.isCommonTest) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         _showCommonTestIntro();
       });
    } else {
      _loadQuestions();
    }
  }

  void _showCommonTestIntro() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text("${widget.chapter} - Common Test", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You are about to start the Full Chapter Challenge. This is a comprehensive test covering all subtopics in this chapter.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.help_outline, "20-30 Questions"),
            _buildDetailRow(Icons.timer, "60 seconds per question"),
            _buildDetailRow(Icons.auto_awesome, "Mastery-based assessment"),
            const SizedBox(height: 16),
            const Text(
              "Completing this will unlock tailored practice for your weak areas and mark the chapter as progress complete.",
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz
            },
            child: const Text("Not Now", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _loadQuestions(); // Actually load questions now
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: const Text("Start Challenge", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _loadQuestions() async {
    _startTime = DateTime.now();
    _questionStartTime = DateTime.now();
    try {
      final List<dynamic> questions;
      if (widget.isCommonTest && widget.chapter != null) {
        questions = await ApiService.getCommonTestQuestions(
          widget.chapter!,
          subject: widget.subject,
        );
      } else {
        questions = await ApiService.getQuestions(
          widget.difficulty?.toLowerCase(), // Can be null
          subject: widget.subject,
          chapter: widget.chapter,
          topic: widget.topic,
        );
      }
      
      setState(() {
        _questions = questions;
        _isLoading = false;
        _remainingSeconds = 60; // 60 seconds per question
        
        // Resolve actual difficulty from the first question if possible
        if (questions.isNotEmpty && questions[0]['difficulty'] != null) {
          _resolvedDifficulty = questions[0]['difficulty'].toString();
        }
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 60; // Reset for the current question
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    // If time is up, we move to next question or submit
    if (_currentIndex < (_questions?.length ?? 0) - 1) {
      // Record "time out" answer
      final q = _questions![_currentIndex];
      final timeSpent = DateTime.now().difference(_questionStartTime!).inSeconds;
      _answers.add({
        'question_id': q['id'],
        'is_correct': false,
        'time_spent': timeSpent,
      });

      setState(() {
        _currentIndex++;
        _textController.clear();
        _questionStartTime = DateTime.now();
      });
      _startTimer();
    } else {
      _submitQuiz();
    }
  }

  void _submitQuiz() async {
    debugPrint('DEBUG: _submitQuiz called');
    _timer?.cancel();
    // Branch to adaptive if chapter is present
    if (widget.chapter != null) {
      _submitAdaptive();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final accuracy = _score / (_questions?.length ?? 1);
    final timeTaken = DateTime.now().difference(_startTime!).inSeconds;
    
    try {
      await ApiService.submitQuizResult({
        'accuracy': accuracy,
        'time': timeTaken,
        'topic_mastery': accuracy, // Basic heuristic for demo
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close loader
        _showResultDialog(accuracy);
      }
    } catch (e, stack) {
      debugPrint('ERROR: Result save failed: $e');
      debugPrint(stack.toString());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save result: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _submitAdaptive() async {
    debugPrint('DEBUG: _submitAdaptive called for chapter ${widget.chapter}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final qCount = _questions?.length ?? 0;
    final totalQuestions = qCount > 0 ? qCount : 1;
    final accuracy = _score / totalQuestions;
    final timeTaken = DateTime.now().difference(_startTime!).inSeconds;

    try {
      final response = await ApiService.submitAdaptiveTest({
        'chapter': widget.chapter,
        'subtopic': widget.topic,
        'score': _score,
        'total_questions': totalQuestions,
        'time_taken': timeTaken, // In seconds
        'mastery_level': accuracy, // Using accuracy as proxy for mastery
        'difficulty_level': _resolvedDifficulty?.toLowerCase() == "hard" ? 2 : (_resolvedDifficulty?.toLowerCase() == "medium" ? 1 : 0),
        'answers': _answers, // Send tracked answers
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close loader
        
        if (widget.isCommonTest) {
          // Skip result dialog and go direct to Learning tab
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                initialIndex: 1,
                initialSubject: widget.subject,
                extraData: {
                  'common_test_complete': widget.chapter,
                  'common_test_score': accuracy,
                  'expand_chapter': widget.chapter,
                },
              ),
            ),
            (route) => false,
          );
        } else {
          _showAdaptiveResultDialog(response);
        }
      }
    } catch (e, stack) {
      debugPrint('ERROR: Submission failed: $e');
      debugPrint(stack.toString());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit adaptive test: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showAdaptiveResultDialog(Map<String, dynamic> response) {
    final action = response['action']; // "ADVANCE" or "RETRY"
    final message = response['message'];
    final newDiff = response['new_difficulty'];
    final recommendedChapter = response['recommended_chapter'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(action == "ADVANCE" ? 'Well Done!' : 'Keep Practicing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            if (action == "RETRY" && newDiff == 0)
              const Text("Switching to Easy mode to build fundamentals.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            if (action == "ADVANCE")
               const Text("You are ready for the next chapter!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            if (recommendedChapter != null)
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text("Next Recommended: $recommendedChapter", style: const TextStyle(fontWeight: FontWeight.bold)),
               ),
            if (response['recommended_subtopic'] != null)
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text("Focus Area: ${response['recommended_subtopic']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
               ),
            if (response['fallback_topics'] != null && (response['fallback_topics'] as List).isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(top: 12.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text("Weak Areas Identified:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                     const SizedBox(height: 4),
                     ...(response['fallback_topics'] as List).map((topic) => 
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                          child: Text("• $topic", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        )
                     ),
                   ],
                 ),
               ),
          ],
        ),
        actions: [
          if (widget.isCommonTest)
             ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(
                        initialIndex: 1, 
                        initialSubject: widget.subject,
                        extraData: {'common_test_complete': widget.chapter},
                      ),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Back to Modules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
          else ...[
            if (recommendedChapter != null && action == "ADVANCE")
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dialog
                  // Restart quiz with new chapter
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => QuizPlayerScreen(
                        difficulty: "medium", // Reset to medium/standard for next chapter
                        subject: widget.subject,
                        chapter: recommendedChapter,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Start Next Chapter', style: TextStyle(color: Colors.white)),
              ),
            if (action == "RETRY" && response['recommended_subtopic'] != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => QuizPlayerScreen(
                        difficulty: null,  // Keep adaptive
                        subject: widget.subject,
                        chapter: widget.chapter,
                        topic: response['recommended_subtopic'],  // Focus on weak topic
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Study Weak Section (Topic)', style: TextStyle(color: Colors.white)),
              ),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => QuizPlayerScreen(
                    difficulty: widget.difficulty, // Original difficulty (null if adaptive)
                    subject: widget.subject,
                    chapter: widget.chapter,
                    topic: widget.topic,
                    isCommonTest: widget.isCommonTest,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('Retake Current Section', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(
                    initialIndex: 1, // Learning tab
                    initialSubject: widget.subject,
                  ),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Open Chapter Modules', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(double accuracy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: Text('Your accuracy: ${(accuracy * 100).toInt()}%'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(
                    initialIndex: 1, // Learning tab
                    initialSubject: widget.subject,
                  ),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Open Chapter Modules', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              // Restart by pushing a replacement of the same screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => QuizPlayerScreen(
                    difficulty: widget.difficulty, // Original difficulty (null if adaptive)
                    subject: widget.subject,
                    chapter: widget.chapter,
                    topic: widget.topic,
                    isCommonTest: widget.isCommonTest,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Retake Quiz', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(); // quiz screen
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Test?'),
        content: const Text('Are you sure you want to end this test? Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Test'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _isExiting = true);
              Navigator.pop(context); // Close dialog
              Future.microtask(() {
                if (mounted) Navigator.pop(context); // Exit quiz
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Test', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isExiting,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitConfirmation(context);
      },
      child: _buildQuizContent(context),
    );
  }

  Widget _buildQuizContent(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _showExitConfirmation(context),
            tooltip: 'Exit',
          ),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text('Error: $_errorMessage')));
    }

    if (_questions == null || _questions!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _showExitConfirmation(context),
            tooltip: 'Exit',
          ),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'No questions found for ${widget.topic ?? "this area"} at the current level.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tip: Try completing the "Full Chapter Challenge" (Common Test) first to unlock more adaptive questions!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions![_currentIndex];
    final data = q['data'] as Map<String, dynamic>?;
    if (data == null) {
      return Scaffold(body: Center(child: Text('Error: Question data is null')));
    }
    final options = (data['options'] is List) ? (data['options'] as List<dynamic>) : [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _showExitConfirmation(context),
          tooltip: 'End Test',
        ),
        title: Text('${widget.isCommonTest ? "COMMON TEST" : (widget.chapter ?? widget.subject)} - ${widget.isCommonTest ? "STANDARD" : (_resolvedDifficulty ?? widget.difficulty ?? "ADAPTIVE").toUpperCase()}'),
        backgroundColor: Colors.deepPurple,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 30 ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 18, color: _remainingSeconds < 30 ? Colors.red : Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _remainingSeconds < 30 ? Colors.red : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions!.length,
              backgroundColor: Colors.grey.shade200,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${_questions!.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    options.isNotEmpty ? 'MULTIPLE CHOICE' : 'FILL IN THE BLANK',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (q['topic'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Topic: ${q['topic']}",
                  style: TextStyle(color: Colors.deepPurple.shade300, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            Text(
              (data['question_text'] ?? data['question'])?.toString() ?? 'Question text missing',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            if (options.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedAnswers[_currentIndex] == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAnswers[_currentIndex] = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Text(options[index]?.toString() ?? 'Option ${index + 1}'),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: TextField(
                  controller: _textController,
                  onChanged: (val) {
                    setState(() {
                      _textAnswers[_currentIndex] = val;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Type your answer here',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (options.isNotEmpty && _selectedAnswers[_currentIndex] == null) ||
                           (options.isEmpty && (_textAnswers[_currentIndex] == null || _textAnswers[_currentIndex]!.trim().isEmpty))
                    ? null
                    : () {
                        // Check if correct
                        bool isCorrect = false;
                        if (options.isNotEmpty) {
                          final correctOptionLetter = data['answer']; // "A", "B", etc.
                          final selectedLetter = String.fromCharCode('A'.codeUnitAt(0) + _selectedAnswers[_currentIndex]!);
                          isCorrect = selectedLetter == correctOptionLetter;
                        } else {
                          final correctAnswer = data['answer'].toString().trim().toLowerCase();
                          final userAnswer = _textAnswers[_currentIndex]!.trim().toLowerCase();
                          isCorrect = userAnswer == correctAnswer;
                        }
                        
                        if (isCorrect) {
                          _score++;
                        }
                        
                        // Record answer for adaptive analysis
                        final timeSpent = DateTime.now().difference(_questionStartTime!).inSeconds;
                        _answers.add({
                          'question_id': q['id'], 
                          'is_correct': isCorrect,
                          'time_spent': timeSpent,
                          'topic': q['topic'], // Pass topic to backend to avoid nulls
                        });

                        if (_currentIndex < _questions!.length - 1) {
                          setState(() {
                            _currentIndex++;
                            _textController.clear();
                            _questionStartTime = DateTime.now();
                          });
                          _startTimer(); // Restart timer for next question
                        } else {
                          _submitQuiz();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex < _questions!.length - 1 ? 'Next Question' : 'Finish Quiz',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
