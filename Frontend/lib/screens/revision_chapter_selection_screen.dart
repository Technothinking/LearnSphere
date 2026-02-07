import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'revision_screen.dart';

class RevisionChapterSelectionScreen extends StatefulWidget {
  final String subject;

  const RevisionChapterSelectionScreen({super.key, required this.subject});

  @override
  State<RevisionChapterSelectionScreen> createState() => _RevisionChapterSelectionScreenState();
}

class _RevisionChapterSelectionScreenState extends State<RevisionChapterSelectionScreen> {
  late Future<List<String>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = ApiService.getChapters(widget.subject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Revise: ${widget.subject}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
          } else {
            final chapters = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.menu_book, color: Colors.amber),
                    title: Text(
                      chapters[index],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Read Textbook Notes", style: TextStyle(color: Colors.white54)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RevisionScreen(
                            subject: widget.subject,
                            chapter: chapters[index],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
