import 'package:flutter/material.dart';
import 'Dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Green theme palette
  final Color navy = const Color(0xFF071224);
  final Color slate = const Color(0xFF0F1720);
  final Color green1 = const Color(0xFF16A34A); // primary green
  final Color green2 = const Color(0xFF22C55E); // lighter green
  final Color cardBg = Colors.white.withOpacity(0.04);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.99, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = navy;
    final textStyleTitle = const TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    final textStyleBody = const TextStyle(color: Colors.white70);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "LearnSphere",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        actions: [
          // XP chip (green)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [green1.withOpacity(0.96), green2.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.36),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.bolt, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  "2,450 XP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // notifications with badge
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
                color: Colors.white70,
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: scaffoldBg, width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
            color: Colors.white70,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HERO card (green gradient)
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        green1.withOpacity(0.95),
                        green2.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.38),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Chip(
                        label: Text(
                          "Personalized AI Learning",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        backgroundColor: Colors.white10,
                      ),
                      const SizedBox(height: 14),
                      Text("Your Personalized Path", style: textStyleTitle),
                      const SizedBox(height: 8),
                      Text(
                        "Adaptive AI builds a learning plan just for you.",
                        style: textStyleBody,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Search lessons, topics or practice",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            color: Colors.white12,
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.qr_code_scanner),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Progress + Week row
              Row(
                children: [
                  Expanded(
                    child: _smallInfoCard(
                      title: "Progress",
                      subtitle: "Mathematics 78%",
                      progress: 0.78,
                      accent: green2,
                      bg: cardBg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _smallInfoCard(
                      title: "This Week",
                      subtitle: "19 lessons",
                      progress: 0.68,
                      accent: green1,
                      bg: cardBg,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Quick Actions
              const Text(
                "Quick Actions",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _quickTile(
                      icon: Icons.play_arrow,
                      title: "Start Lesson",
                      subtitle: "Continue where you left",
                      color: green1,
                    ),
                    const SizedBox(width: 12),
                    _quickTile(
                      icon: Icons.quiz,
                      title: "Practice",
                      subtitle: "Short quizzes",
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 12),
                    _quickTile(
                      icon: Icons.book,
                      title: "Revision",
                      subtitle: "Flashcards",
                      color: Colors.tealAccent.shade200,
                    ),
                    const SizedBox(width: 12),
                    _quickTile(
                      icon: Icons.leaderboard,
                      title: "Leaderboard",
                      subtitle: "See top students",
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Recommended carousel
              const Text(
                "Recommended for you",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, idx) => _courseCard(idx, green1),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: 4,
                ),
              ),

              const SizedBox(height: 22),

              // Achievements
              _achievementsCard(cardBg),

              const SizedBox(height: 18),

              Center(
                child: Text(
                  "Keep learning — small steps every day 🚀",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),

      // Floating action: round FAB + small pill label (green)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "start",
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
            backgroundColor: green1,
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Let's Start",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- helper widgets ----------
  static Widget _smallInfoCard({
    required String title,
    required String subtitle,
    required double progress,
    required Color accent,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: accent,
              backgroundColor: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _quickTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.18),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _courseCard(int idx, Color green1) {
    final titles = [
      "Algebra Basics",
      "Physics: Motion",
      "Chemistry: Atoms",
      "Programming 101",
    ];
    final progress = [0.6, 0.35, 0.8, 0.25][idx % 4];

    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            green1.withOpacity(0.95 - idx * 0.06),
            Colors.greenAccent.withOpacity(0.6 - idx * 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titles[idx % titles.length],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${(progress * 100).toInt()}% complete",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: Colors.black,
                ),
                label: const Text(
                  "Resume",
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.more_horiz, color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _achievementsCard(Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Recent Achievements",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.star, color: Colors.white),
            ),
            title: Text("Quiz Master", style: TextStyle(color: Colors.white)),
            subtitle: Text(
              "Unlocked today!",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text("Week Warrior", style: TextStyle(color: Colors.white)),
            subtitle: Text(
              "Unlocked today!",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.light_mode, color: Colors.white),
            ),
            title: Text("Precision Pro", style: TextStyle(color: Colors.white)),
            subtitle: Text(
              "Unlocked today!",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          Divider(color: Colors.white12),
          Center(
            child: Text(
              "+250 XP earned this week",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
