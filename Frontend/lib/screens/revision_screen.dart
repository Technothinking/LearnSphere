import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';

class RevisionScreen extends StatefulWidget {
  final String subject;
  final String chapter;

  const RevisionScreen({
    super.key,
    required this.subject,
    required this.chapter,
  });

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  late Future<String> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = ApiService.getChapterNotes(widget.subject, widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("${widget.chapter} Notes"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading revision notes:\n${snapshot.error}",
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else {
            final markdown = snapshot.data ?? "No notes found.";
            return Markdown(
              data: markdown,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                p: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                listBullet: const TextStyle(color: Colors.white70, fontSize: 16),
                strong: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
                code: TextStyle(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: Colors.yellowAccent,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
