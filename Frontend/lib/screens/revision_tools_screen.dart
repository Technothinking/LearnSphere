import 'package:flutter/material.dart';

class RevisionToolsScreen extends StatelessWidget {
  const RevisionToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        _buildSectionHeader("Recommended by AI"),
        const SizedBox(height: 12),
        _buildAIRecommendCard(context),
        const SizedBox(height: 24),
        
        _buildSectionHeader("Revision Tools"),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildToolCard("Flashcards", Icons.style, Colors.amber.shade700),
            _buildToolCard("Practice Quiz", Icons.timer, Colors.amber.shade600),
            _buildToolCard("Formula Sheets", Icons.functions, Colors.amber.shade500),
            _buildToolCard("Mistake Log", Icons.history_edu, Colors.amber.shade400),
          ],
        ),
        
        const SizedBox(height: 32),
        _buildSectionHeader("Recent Revision"),
        const SizedBox(height: 12),
        _buildRecentFlashcard(context, "Last Topic Studied", "Auto-saved"),
        _buildRecentFlashcard(context, "Formula Review", "Practice Mode"),
      ],
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

  Widget _buildAIRecommendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Strengthen your Weak Spots",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  "Based on your last quiz, the AI suggests reviewing your recent topics.",
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Starting practice...")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Start Practice"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFlashcard(BuildContext context, String title, String subject) {
    return Card(
      color: Colors.white.withOpacity(0.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.style, color: Colors.amber),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subject, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Opening flashcard: $title")),
          );
        },
      ),
    );
  }
}
