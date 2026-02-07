import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'quiz_player_screen.dart';
import 'Dashboard.dart';

class ChapterSelectionScreen extends StatefulWidget {
  final String subject;

  const ChapterSelectionScreen({super.key, required this.subject});

  @override
  State<ChapterSelectionScreen> createState() => _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState extends State<ChapterSelectionScreen> {
  List<String>? _chapters;
  List<dynamic> _completedChapters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    try {
      print('DEBUG: ChapterSelectionScreen loading for subject ${widget.subject}');
      final chapters = await ApiService.getChapters(widget.subject);
      final diagnostic = await ApiService.getDiagnosticStatus();
      
      print('DEBUG: Diagnostic status for ${widget.subject}: $diagnostic');
      
      setState(() {
        _chapters = chapters;
        _completedChapters = diagnostic['completed_chapters'] ?? [];
        _isLoading = false;
      });
      print('DEBUG: Completed chapters in state: $_completedChapters');
    } catch (e) {
      print('ERROR: Failed to load chapters or diagnostic: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isChapterCompleted(String chapterName) {
    if (_completedChapters.isEmpty) return false;
    
    final String targetName = chapterName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    
    // Fuzzy matching: ignore casing, spaces, and symbols
    return _completedChapters.any((e) {
      final String compName = e.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      
      final bool match = (compName == targetName) || 
                         (compName.isNotEmpty && targetName.isNotEmpty && (compName.contains(targetName) || targetName.contains(compName)));
      
      if (match) {
        print('DEBUG: Match found! "$chapterName" matches "$e"');
      }
      return match;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Chapters'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }

    if (_chapters == null || _chapters!.isEmpty) {
      return const Center(child: Text('No chapters found for this subject.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chapters!.length,
      itemBuilder: (context, index) {
        final chapter = _chapters![index];
        final isCompleted = _isChapterCompleted(chapter);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isCompleted ? Colors.green.withOpacity(0.1) : Colors.deepPurple.withOpacity(0.1),
              child: isCompleted 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Text(
                    "${index + 1}",
                    style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
            ),
            title: Text(
              chapter,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              isCompleted ? "Completed! Go to Focus Zones." : "Tap to take Common Test",
              style: TextStyle(color: isCompleted ? Colors.green : Colors.black54),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (isCompleted) {
                // If done, go to Learning Modules tab (index 1) and expand this chapter
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(
                      initialIndex: 1,
                      initialSubject: widget.subject,
                      extraData: {
                        'expand_chapter': chapter,
                      },
                    ),
                  ),
                  (route) => false,
                );
              } else {
                // Otherwise, start common test
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuizPlayerScreen(
                      difficulty: null, 
                      subject: widget.subject,
                      chapter: chapter,
                      isCommonTest: true,
                    ),
                  ),
                ).then((_) => _loadChapters());
              }
            },
          ),
        );
      },
    );
  }
}
