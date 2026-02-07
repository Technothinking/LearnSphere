import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'quiz_player_screen.dart';

class LearningModulesScreen extends StatefulWidget {
  final String? initialSubject;
  final Map<String, dynamic>? extraData;
  const LearningModulesScreen({super.key, this.initialSubject, this.extraData});

  @override
  State<LearningModulesScreen> createState() => _LearningModulesScreenState();
}

class _LearningModulesScreenState extends State<LearningModulesScreen> with AutomaticKeepAliveClientMixin {
  List<String>? _subjects;
  String? _selectedSubject;
  List<String>? _chapters;
  Map<String, dynamic>? _masteryData;
  List<dynamic> _completedChapters = [];
  bool _isLoading = true;
  bool _hasShownCompleteDialog = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      print('DEBUG: Loading initial data for subject $_selectedSubject...');
      final subs = await ApiService.getSubjects();
      if (mounted) {
        setState(() {
          _subjects = subs;
          if (widget.initialSubject != null && subs.contains(widget.initialSubject)) {
            _selectedSubject = widget.initialSubject;
          } else if (subs.isNotEmpty && _selectedSubject == null) {
            _selectedSubject = subs[0];
          }
        });
        if (_selectedSubject != null) {
          await _loadChapters(_selectedSubject!);
        }
        
        print('DEBUG: Fetching mastery and diagnostic status...');
        final mastery = await ApiService.getMasteryStatus();
        final diagnostic = await ApiService.getDiagnosticStatus();
        
        print('DEBUG: Mastery keys: ${mastery.keys.toList()}');
        print('DEBUG: Diagnostic response: $diagnostic');
        
          if (mounted) {
            setState(() {
              _masteryData = mastery;
              _completedChapters = diagnostic['completed_chapters'] ?? [];
              _isLoading = false; 
            });
            print('DEBUG: Data loaded successfully. Completed chapters: $_completedChapters');
            
            // Check for common test completion dialogue - ONLY IF NOT SHOWN BEFORE
            if (!_hasShownCompleteDialog && widget.extraData != null && widget.extraData!['common_test_complete'] != null) {
               _hasShownCompleteDialog = true;
               final String chapterName = widget.extraData!['common_test_complete'];
               final double? score = widget.extraData!['common_test_score'];
               
               // Identify weak areas for this chapter from the mastery we just loaded
               List<String> weakAreas = [];
               final chapterData = _masteryData?[chapterName];
               if (chapterData is Map) {
                 chapterData.forEach((topic, data) {
                   if (topic != "CHAPTER_COMPLETE" && data is Map) {
                     final double acc = (data['accuracy'] ?? 0.0).toDouble();
                     if (acc < 0.7) weakAreas.add(topic);
                   }
                 });
               }

               // Delay slightly to ensure UI is ready
               Future.microtask(() {
                 if (mounted) _showCommonTestCompleteDialog(chapterName, score: score, weakAreas: weakAreas);
               });
            }
          }
      }
    } catch (e) {
      print('ERROR: Failed to load initial data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCommonTestCompleteDialog(String chapter, {double? score, List<String>? weakAreas}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text("Test Completed!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (score != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Score: ", style: TextStyle(color: Colors.white70)),
                    Text(
                      "${(score * 100).toInt()}%",
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            Text(
              "Great job finishing the Full Chapter Challenge for $chapter! Your mastery levels have been updated.",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            if (weakAreas != null && weakAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Focus Areas (Scored < 70%):",
                style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...weakAreas.take(4).map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, color: Colors.redAccent, size: 16),
                    Expanded(child: Text(topic, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              const Text(
                "Try taking the individual section quizzes for these subtopics to improve!",
                style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ] else if (weakAreas != null) ...[
              const SizedBox(height: 16),
              const Text(
                "You've handled all topics exceptionally well! Keep it up.",
                style: TextStyle(color: Colors.greenAccent, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
            child: const Text("Got it", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadChapters(String subject) async {
    setState(() => _isLoading = true);
    try {
      final chaps = await ApiService.getChapters(subject);
      if (mounted) {
        setState(() {
          _chapters = chaps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading && _subjects == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGenerationDialog,
         backgroundColor: Colors.deepPurple,
         icon: const Icon(Icons.auto_awesome),
         label: const Text("AI Generate"),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildSectionHeader("My Subjects"),
        const SizedBox(height: 16),
        if (_subjects == null || _subjects!.isEmpty)
          const Text("No subjects found", style: TextStyle(color: Colors.white70))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _subjects!.map((s) {
                final isSelected = s == _selectedSubject;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedSubject = s);
                        _loadChapters(s);
                      }
                    },
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                  ),
                );
              }).toList(),
            ),
          ),
        
        const SizedBox(height: 24),
        
        if (_selectedSubject != null) ...[
          _buildSubjectCard(
            context: context,
            title: _selectedSubject!,
            chapters: _chapters?.length ?? 0,
            mastery: 0.5, // Mock value
            difficulty: "Standard",
            color: Colors.indigo.shade600,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Chapters in $_selectedSubject"),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_chapters == null || _chapters!.isEmpty)
            const Text("No chapters found", style: TextStyle(color: Colors.white70))
          else
            ..._chapters!.map((c) {
              final chapterData = _masteryData?[c];
              final Map<String, dynamic>? chapterMastery = (chapterData is Map) ? Map<String, dynamic>.from(chapterData) : null;
              
              // New structure: chapterMastery['CHAPTER_COMPLETE'] is a Map
              final bool isChapterCompleted = (chapterMastery?['CHAPTER_COMPLETE'] is Map) 
                  ? chapterMastery!['CHAPTER_COMPLETE']['is_completed'] ?? false
                  : (chapterMastery?['CHAPTER_COMPLETE'] == true);
                  
              // Strict check: match by name while ignoring casing, spaces, and symbols
              final bool isCommonTestCompletedInList = _completedChapters.any((e) {
                final String compName = e.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
                final String targetName = c.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
                return compName == targetName;
              });
              
              final bool isCommonTestCompleted = isCommonTestCompletedInList || isChapterCompleted;
              
              print('DEBUG: [LearningModules] Chapter: "$c"');
              print('   - In Completed List: $isCommonTestCompletedInList (List: $_completedChapters)');
              print('   - Mastery Completed: $isChapterCompleted (Mastery: ${chapterMastery?['CHAPTER_COMPLETE']})');
              print('   - FINAL RESULT: $isCommonTestCompleted');

              return Column(
                children: [
                   ChapterExpansionTile(
                    subject: _selectedSubject!,
                    chapter: c,
                    completed: isChapterCompleted,
                    masteryData: chapterMastery,
                    isCommonTestCompleted: isCommonTestCompleted,
                    onRefresh: _loadInitialData,
                    initiallyExpanded: widget.extraData?['expand_chapter'] == c,
                  ),
                  // Redundant badge removed as per user feedback (completion status shown inside tile)
                  /*
                  if (isCommonTestCompleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.withOpacity(0.5)),
                            ),
                            child: const Text(
                              "COMMON TEST COMPLETED",
                              style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  */
                ],
              );
            }),
          const SizedBox(height: 24),
          _buildInsightsCard(context),
        ],
      ],
    ),
  );
}

  // --- Generation UI ---
  void _showGenerationDialog() {
    final filenameController = TextEditingController();
    final chapterController = TextEditingController(); // Or dropdown if strict

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Generate AI Content", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Upload a PDF to Supabase 'Textbook' bucket first.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: filenameController,
              decoration: const InputDecoration(
                labelText: "PDF Filename (e.g. force.pdf)",
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chapterController,
              decoration: const InputDecoration(
                labelText: "Chapter Name (e.g. Force)",
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Triggering BULK AI for ALL Chapters... 🚀")),
                );
                try {
                  await ApiService.triggerBulkGeneration();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bulk generation Queued! Checks logs.")),
                  );
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              icon: const Icon(Icons.layers, color: Colors.amberAccent),
              label: const Text("Scan Entire Bucket (All Chapters)", style: TextStyle(color: Colors.amberAccent)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final file = filenameController.text.trim();
              final chap = chapterController.text.trim();
              if (file.isEmpty || chap.isEmpty) return;

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Triggering AI... check console/logs")),
              );

              try {
                await ApiService.triggerContentGeneration(
                  filename: file,
                  subject: _selectedSubject ?? "Physics", // Default or current
                  chapter: chap,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Generation queued for $chap!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Generate"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubjectCard({
    required BuildContext context,
    required String title,
    required int chapters,
    required double mastery,
    required String difficulty,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "$chapters chapters • ${(mastery * 100).toInt()}% mastered",
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: mastery,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Continuing $title...")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Continue"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterItem(String title, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? Colors.green : Colors.white24,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: completed ? Colors.white : Colors.white60,
                fontSize: 16,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white12),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade900, Colors.indigo.shade900],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                "AI Insights",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Your AI brain is analyzing your progress. Complete more quizzes to get personalized tips!",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ChapterExpansionTile extends StatefulWidget {
  final String subject;
  final String chapter;
  final bool completed;
  final Map<String, dynamic>? masteryData;
  final bool isCommonTestCompleted;
  final VoidCallback? onRefresh;
  final bool initiallyExpanded;

  const ChapterExpansionTile({
    super.key,
    required this.subject,
    required this.chapter,
    required this.completed,
    this.masteryData,
    this.isCommonTestCompleted = false,
    this.onRefresh,
    this.initiallyExpanded = false,
  });

  @override
  State<ChapterExpansionTile> createState() => _ChapterExpansionTileState();
}

class _ChapterExpansionTileState extends State<ChapterExpansionTile> {
  List<String>? _topics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) {
      _fetchTopics();
    }
  }

  Future<void> _fetchTopics() async {
    if (_topics != null) return;
    setState(() => _isLoading = true);
    try {
      final topics = await ApiService.getTopics(widget.subject, widget.chapter);
      if (mounted) {
        setState(() {
          _topics = topics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFallbackTopics(BuildContext context) {
    if (_topics == null) return;
    
    // Identify fallback topics: those with accuracy < 0.7 or not started
    final fallbacks = _topics!.where((topic) {
      final data = widget.masteryData?[topic];
      if (data == null) return true; // Not started
      if (data is Map) {
        final double acc = (data['accuracy'] ?? 0.0).toDouble();
        final bool isComp = data['is_completed'] ?? false;
        return acc < 0.7 && !isComp;
      }
      return false;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review Suggested Topics",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "You've completed the common test for ${widget.chapter}! Based on your performance, we recommend focusing on these areas:",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...fallbacks.take(3).map((topic) => ListTile(
              dense: true,
              title: Text(topic, style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepPurpleAccent),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuizPlayerScreen(
                      difficulty: null,
                      subject: widget.subject,
                      chapter: widget.chapter,
                      topic: topic,
                    ),
                  ),
                );
              },
            )),
            if (fallbacks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("You've mastered all topics! Great job!", style: TextStyle(color: Colors.greenAccent))),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (expanded) {
          if (expanded) _fetchTopics();
        },
        leading: Icon(
          (widget.completed || widget.isCommonTestCompleted) ? Icons.check_circle : Icons.circle_outlined,
          color: widget.completed ? Colors.green : (widget.isCommonTestCompleted ? Colors.blue : Colors.white24),
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.chapter,
                style: TextStyle(
                  color: (widget.completed || widget.isCommonTestCompleted) ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!widget.isCommonTestCompleted)
              IconButton(
                icon: const Icon(Icons.quiz_outlined, size: 18, color: Colors.indigoAccent),
                tooltip: "Quick Common Test",
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuizPlayerScreen(
                        difficulty: null,
                        subject: widget.subject,
                        chapter: widget.chapter,
                        isCommonTest: true,
                      ),
                    ),
                  ).then((_) => widget.onRefresh?.call());
                },
              ),
          ],
        ),
        trailing: const Icon(Icons.expand_more, color: Colors.white54, size: 20),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_topics == null || _topics!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No sections found for this chapter.", style: TextStyle(color: Colors.white54, fontSize: 12)),
            )
          else ...[
            // Check for fallbacks (low accuracy)
            if (_topics != null) ...[
              () {
                // Determine if we should show fallbacks: accuracy < 0.7 
                final lowMastery = _topics!.where((t) {
                  final data = widget.masteryData?[t];
                  if (data is Map) {
                    final String? action = data['last_action'];
                    final double acc = (data['accuracy'] ?? 0.0).toDouble();
                    // Priority 1: PPO Model says RETRY
                    if (action == "RETRY") return true;
                    // Priority 2: Very low accuracy even if no action yet
                    return acc > 0 && acc < 0.7;
                  }
                  return false;
                }).toList();

                if (lowMastery.isNotEmpty && widget.isCommonTestCompleted) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 16),
                              SizedBox(width: 8),
                              Text(
                                "Focus Required",
                                style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You're struggling with: ${lowMastery.join(', ')}. Try practicing these again to improve your score!",
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }(),
            ],
            for (final topic in _topics!)
              _buildTopicItem(context, topic, widget.masteryData?[topic], isLocked: !widget.isCommonTestCompleted),
          ],
          
          // Add a "Common Test" option at the bottom of topics (only if not completed)
          if (!widget.isCommonTestCompleted) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Divider(color: Colors.white.withOpacity(0.05)),
            ),
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.star_border,
                color: Colors.deepPurpleAccent,
                size: 20,
              ),
              title: const Text(
                "Full Chapter Challenge", 
                style: TextStyle(
                  color: Colors.deepPurpleAccent, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13
                )
              ),
              subtitle: const Text(
                "Take the common test for the whole chapter", 
                style: TextStyle(color: Colors.white30, fontSize: 11)
              ),
              trailing: const Icon(
                Icons.play_circle_fill, 
                color: Colors.deepPurpleAccent, 
                size: 24
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuizPlayerScreen(
                      difficulty: null, // chapter test
                      subject: widget.subject,
                      chapter: widget.chapter,
                      isCommonTest: true,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicItem(BuildContext context, String topic, dynamic masteryData, {bool isLocked = false}) {
    bool isCompleted = false;
    int level = 0;
    double accuracy = 0.0;
    double mastery = 0.0;
    if (masteryData is Map) {
      isCompleted = masteryData['is_completed'] ?? false;
      level = masteryData['level'] ?? 0;
      accuracy = (masteryData['accuracy'] ?? 0.0).toDouble();
      mastery = (masteryData['mastery'] ?? 0.0).toDouble();
    } else if (masteryData is bool) {
      isCompleted = masteryData;
    }

    String levelLabel = "";
    Color levelColor = Colors.blueAccent;
    
    // PPO-driven Retry Logic
    final String? lastAction = masteryData is Map ? masteryData['last_action'] : null;
    bool needsRetry = (lastAction == "RETRY") || (accuracy > 0 && accuracy < 0.7);

    if (!isLocked) {
      if (level == 0) {
        levelLabel = "BEGINNER";
      } else if (level == 1) levelLabel = "INTERMEDIATE";
      else if (level == 2) levelLabel = "MASTER";
      
      if (accuracy > 0) {
        levelLabel += " • ${(accuracy * 100).toInt()}%";
      }

      // Mastery based color
      if (needsRetry) {
        levelColor = Colors.redAccent;
      } else if (mastery < 0.7 && isCompleted) levelColor = Colors.orangeAccent;
      else if (isCompleted) levelColor = Colors.greenAccent;
    }

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      enabled: !isLocked,
      leading: Icon(
        isLocked 
          ? Icons.lock_outline 
          : (isCompleted 
              ? (needsRetry ? Icons.error_outline : Icons.check_circle) 
              : Icons.circle_outlined),
        color: isLocked 
          ? Colors.white24 
          : (isCompleted 
              ? (needsRetry ? Colors.redAccent : Colors.greenAccent) 
              : (accuracy > 0 ? Colors.blueAccent : Colors.white24)),
        size: 16,
      ),
      title: Row(
        children: [
          if (needsRetry)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.redAccent, blurRadius: 4),
                ],
              ),
            ),
          Expanded(
            child: Text(
              topic,
              style: TextStyle(
                color: isLocked ? Colors.white24 : (isCompleted ? Colors.white : Colors.white60), 
                fontSize: 14
              ),
            ),
          ),
          if (levelLabel.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                levelLabel,
                style: TextStyle(color: levelColor, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          if (needsRetry)
             Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "RETRY REQUIRED",
                style: TextStyle(color: Colors.redAccent, fontSize: 7, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLocked 
              ? Colors.grey.withOpacity(0.1) 
              : (isCompleted)
                  ? (needsRetry ? Colors.red.withOpacity(0.1) : (accuracy < 0.7 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)))
                  : Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isLocked 
              ? "Complete Test First" 
              : (isCompleted)
                  ? (mastery < 0.4 ? "Low Mastery" : (mastery < 0.7 ? "Moderate" : "Mastered"))
                  : (level > 0 ? "Continue" : "Start"), 
          style: TextStyle(
            color: isLocked 
                ? Colors.white38 
                : (isCompleted)
                    ? (mastery < 0.4 ? Colors.redAccent : (mastery < 0.7 ? Colors.orangeAccent : Colors.greenAccent))
                    : Colors.deepPurpleAccent, 
            fontSize: 10, 
            fontWeight: FontWeight.bold
          )
        ),
      ),
      onTap: isLocked ? null : () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizPlayerScreen(
              difficulty: null, // Adaptive
              subject: widget.subject,
              chapter: widget.chapter,
              topic: topic,
            ),
          ),
        );
        if (widget.onRefresh != null) widget.onRefresh!();
      },
    );
  }
}
