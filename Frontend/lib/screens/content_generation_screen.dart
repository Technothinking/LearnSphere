import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ContentGenerationScreen extends StatefulWidget {
  const ContentGenerationScreen({super.key});

  @override
  State<ContentGenerationScreen> createState() => _ContentGenerationScreenState();
}

class _ContentGenerationScreenState extends State<ContentGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _filenameController = TextEditingController(text: 'motion.pdf');
  final _subjectController = TextEditingController(text: 'Science');
  final _chapterController = TextEditingController(text: 'Motion');
  
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isError = false;
  List<Map<String, dynamic>>? _textbooks;
  Map<String, dynamic>? _selectedTextbook;

  @override
  void initState() {
    super.initState();
    _loadTextbooks();
  }

  Future<void> _loadTextbooks() async {
    try {
      final textbooks = await ApiService.getTextbooks();
      setState(() {
        _textbooks = textbooks;
      });
    } catch (e) {
      print("Failed to load textbooks: $e");
    }
  }

  Future<void> _startGeneration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "AI is reading and generating questions... This may take a minute.";
      _isError = false;
    });

    try {
      final filename = _filenameController.text.trim();
      final subject = _selectedTextbook != null ? _selectedTextbook!['subject'] : _subjectController.text.trim();
      final chapter = _selectedTextbook != null ? _selectedTextbook!['chapter'] : _chapterController.text.trim();

      final result = await ApiService.triggerContentGeneration(
        filename: filename,
        subject: subject,
        chapter: chapter,
      );

      setState(() {
        _isProcessing = false;
        _statusMessage = result['message'] ?? "Successfully queued for generation!";
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isError = true;
        _statusMessage = "Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("AI Content Lab"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Generate Questions from PDF",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Point to a textbook PDF in your Supabase bucket to automatically generate topics and 30 questions per section.",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              if (_textbooks != null && _textbooks!.isNotEmpty) ...[
                const Text("Select Textbook from Database", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _textbooks!.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text("${t['subject']} - ${t['chapter']} (Grade ${t['grade']})"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTextbook = val;
                      if (val != null) {
                        // Auto-fill filename based on chapter name as a guess
                        _filenameController.text = "${val['chapter'].toString().toLowerCase().replaceAll(' ', '_')}.pdf";
                        _subjectController.text = val['subject'];
                        _chapterController.text = val['chapter'];
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text("Or Manual Entry", style: TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 8),
              ],
              
              _buildTextField("Filename (in Bucket)", _filenameController),
              const SizedBox(height: 16),
              _buildTextField("Subject", _subjectController),
              const SizedBox(height: 16),
              _buildTextField("Chapter", _chapterController),
              
              const SizedBox(height: 40),
              
              if (_isProcessing)
                const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
              else
                ElevatedButton(
                  onPressed: _startGeneration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Start AI Generation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              
              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isError ? Colors.red : Colors.green, width: 0.5),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(color: _isError ? Colors.redAccent : Colors.greenAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) => value == null || value.isEmpty ? "Required field" : null,
        ),
      ],
    );
  }
}
