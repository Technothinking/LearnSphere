import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import 'home_dashboard.dart';
import 'learning_modules_screen.dart';
import 'revision_tools_screen.dart';
import 'support_engagement_screen.dart';
import 'profile_screen.dart';
import 'chapter_selection_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialSubject;
  final Map<String, dynamic>? extraData;
  const DashboardScreen({super.key, this.initialIndex = 0, this.initialSubject, this.extraData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  List<String>? _subjects;
  bool _isLoadingSubjects = true;

  List<Widget> get _pages => [
    HomeDashboard(
      onNavigateToLearning: () => _onItemTapped(1),
      subject: widget.initialSubject ?? (_subjects?.isNotEmpty == true ? _subjects![0] : "Science"),
    ),
    LearningModulesScreen(
      initialSubject: widget.initialSubject,
      extraData: widget.extraData,
    ),
    const RevisionToolsScreen(),
    const SupportEngagementScreen(),
    const FullProfilePage(),
  ];

  late final AnimationController _animController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.99, end: 1.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.repeat(reverse: true);
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final subs = await ApiService.getSubjects();
      if (mounted) {
        setState(() {
          _subjects = subs;
          _isLoadingSubjects = false;
        });
      }
    } catch (e) {
      // Handle error, e.g., log it or show a message
      print('Error loading subjects: $e');
      if (mounted) setState(() => _isLoadingSubjects = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    // fixed height and center-aligned to avoid vertical wrapping
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.14),
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _courseCard(String title, double progress, Color a, Color b) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [a, b]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${(progress * 100).toInt()}% complete",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.white,
              backgroundColor: Colors.white24,
              minHeight: 8,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChapterSelectionScreen(subject: title),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: Colors.black,
                ),
                label: const Text(
                  "Resume",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBg = Color(0xFF071224);
    const Color cardBg = Color(0xFF0F1720);
    const Color accent1 = Color(0xFF16A34A);
    const Color accent2 = Color(0xFF06B6D4);
    const Color accent3 = Color(0xFF5D2CFF);

    // bottom bar height and safe inset handling
    final double bottomBarHeight = kBottomNavigationBarHeight + 12;
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _selectedIndex == 4 ? null : PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            padding: const EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B2540), Color(0xFF07202A)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _onItemTapped(4), // Profile is at index 4
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'Learner'} — let\'s continue learning',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [accent3, accent2]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accent3.withOpacity(0.18),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.bolt, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '2,450 XP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

      body: SafeArea(
        child: Padding(
          padding: _selectedIndex == 4 ? EdgeInsets.zero : const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_selectedIndex == 0) ...[
                // stats row
                // Stats row removed as per request
                
                // search row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Colors.white54),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search lessons, topics or practice',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: cardBg,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list),
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // recommended carousel (reduced height)
                SizedBox(
                  height: 160,
                  child: _isLoadingSubjects
                      ? const Center(child: CircularProgressIndicator())
                      : (_subjects == null || _subjects!.isEmpty)
                          ? const Center(child: Text("No subjects available", style: TextStyle(color: Colors.white70)))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (ctx, idx) {
                                final title = _subjects![idx];
                                return _courseCard(
                                  title, 
                                  0.5, // Mock progress
                                  idx % 2 == 0 ? accent1 : accent3, 
                                  accent2
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemCount: _subjects!.length,
                            ),
                ),

                const SizedBox(height: 14),
              ],

              // content container where pages appear
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder:
                      (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                  child: Container(
                    key: ValueKey<int>(_selectedIndex),
                    padding: _selectedIndex == 4 
                        ? EdgeInsets.zero 
                        : const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 4 ? Colors.transparent : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedIndex == 4 ? null : Border.all(color: Colors.white10),
                    ),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),


      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: kBottomNavigationBarHeight + 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 'Home', 0),
              _navItem(Icons.auto_stories, 'Learning', 1),
              _navItem(Icons.psychology, 'Revision', 2),
              _navItem(Icons.rocket_launch, 'Support', 3),
              _navItem(Icons.person, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx) {
    final selected = idx == _selectedIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? Colors.black87 : Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black87 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
