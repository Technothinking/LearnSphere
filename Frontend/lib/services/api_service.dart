import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // Dynamic base URL based on platform
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    try {
      // Use 10.0.2.2 for Android Emulator, but allow local IP for physical devices
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
      if (Platform.isIOS) return 'http://localhost:8000/api/v1';
    } catch (_) {}
    return 'http://localhost:8000/api/v1';
  }

  static final _supabase = Supabase.instance.client;

  // Simple cache to avoid redundant network hits
  static List<String>? _cachedSubjects;
  static final Map<String, List<String>> _cachedChapters = {};
  static final Map<String, List<String>> _cachedTopics = {}; // { "chapter_name": [topics] }

  // Get current authenticated student ID
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  // Get current authenticated student email
  static String? get currentUserEmail => _supabase.auth.currentUser?.email;

  // Fetch the next adaptive action for current student
  static Future<Map<String, dynamic>> getNextAction() async {
    final studentId = currentUserId;
    if (studentId == null) throw Exception('User not logged in');

    print('API DEBUG: Requesting GET $baseUrl/rl/next-action/$studentId');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rl/next-action/$studentId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load next action: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching next action: $e');
      rethrow;
    }
  }

  // Submit quiz results to the backend
  static Future<Map<String, dynamic>> submitQuizResult(Map<String, dynamic> result) async {
    final studentId = currentUserId;
    if (studentId == null) throw Exception('User not logged in');

    print('API DEBUG: Requesting POST $baseUrl/quizzes/submit?student_id=$studentId');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/submit?student_id=$studentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(result),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting quiz: $e');
      rethrow;
    }
  }

  // Fetch questions based on difficulty (adaptive if difficulty is null)
  static Future<List<dynamic>> getQuestions(String? difficulty, {String? subject, String? chapter, String? topic}) async {
    final studentId = currentUserId;
    try {
      String url = '$baseUrl/quizzes/?limit=30';
      if (difficulty != null) url += '&difficulty=$difficulty';
      if (studentId != null) url += '&student_id=$studentId'; // For adaptive resolution
      if (subject != null) url += '&subject=$subject';
      if (chapter != null) url += '&chapter=$chapter';
      if (topic != null) url += '&topic=$topic';
      
      print('API DEBUG: Requesting GET $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching questions: $e');
      rethrow;
    }
  }

  // Fetch common test questions for a chapter
  static Future<List<dynamic>> getCommonTestQuestions(String chapter, {String? subject}) async {
    try {
      String url = '$baseUrl/quizzes/common-test?chapter=$chapter';
      if (subject != null) url += '&subject=$subject';
      
      print('API DEBUG: Requesting GET $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching common test questions: $e');
      rethrow;
    }
  }

  // Fetch unique subjects
  static Future<List<String>> getSubjects() async {
    final studentId = currentUserId;
    // We cache subjects but if studentId is different or null, we might want to refresh.
    // For now, let's just bypass cache if it's the first hit or if we want strict online.
    
    try {
      String url = '$baseUrl/quizzes/subjects';
      if (studentId != null) url += '?student_id=$studentId';
      
      print('API DEBUG: Requesting GET $url');
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
           _cachedSubjects = List<String>.from(decoded.map((e) => e.toString()));
           return _cachedSubjects!;
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching subjects: $e');
      rethrow;
    }
  }

  // Fetch unique chapters for a subject
  static Future<List<String>> getChapters(String subject) async {
    if (_cachedChapters.containsKey(subject)) return _cachedChapters[subject]!;

    try {
      print('API DEBUG: Requesting GET $baseUrl/quizzes/chapters?subject=$subject');
      final response = await http.get(Uri.parse('$baseUrl/quizzes/chapters?subject=$subject'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          _cachedChapters[subject] = List<String>.from(decoded.map((e) => e.toString()));
          return _cachedChapters[subject]!;
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching chapters: $e');
      rethrow;
    }
  }

  // Fetch unique textbooks (from database table)
  static Future<List<Map<String, dynamic>>> getTextbooks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quizzes/textbooks'))
          .timeout(const Duration(seconds: 10));
      
      print('API Request: GET $baseUrl/quizzes/textbooks -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching textbooks: $e');
      rethrow;
    }
  }

  // Fetch unique topics for a chapter
  static Future<List<String>> getTopics(String subject, String chapter) async {
    final cacheKey = '$subject:$chapter';
    if (_cachedTopics.containsKey(cacheKey)) return _cachedTopics[cacheKey]!;

    try {
      final response = await http.get(Uri.parse('$baseUrl/quizzes/topics?subject=$subject&chapter=$chapter'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          _cachedTopics[cacheKey] = List<String>.from(decoded.map((e) => e.toString()));
          return _cachedTopics[cacheKey]!;
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching topics: $e');
      rethrow;
    }
  }

  // Initialize student in backend (after signup/login)
  static Future<void> setupStudentProfile(int grade) async {
    final user = Supabase.instance.client.auth.currentUser;
    final studentId = user?.id;
    if (studentId == null) return;

    final fullName = user?.userMetadata?['full_name'] ?? "";
    final email = user?.email ?? "";

    final body = {
      'student_id': studentId,
      'grade': grade,
      'full_name': fullName,
      'email': email,
    };

    try {
       print('API DEBUG: Requesting POST $baseUrl/students/ with body: $body');
       final response = await http.post(
        Uri.parse('$baseUrl/students/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      print('API DEBUG: Profile setup response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error setting up student: $e');
    }
  }

  // Submit adaptive test results
  static Future<Map<String, dynamic>> submitAdaptiveTest(Map<String, dynamic> submission) async {
    final studentId = currentUserId;
    if (studentId == null) throw Exception('User not logged in');

    submission['student_id'] = studentId;
    submission['email'] = currentUserEmail;

    print('API DEBUG: Submitting adaptive result to $baseUrl/quizzes/submit/adaptive');
    print('Payload: ${json.encode(submission)}');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/submit/adaptive'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(submission),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit adaptive test: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting adaptive test: $e');
      rethrow;
    }
  }

  // Fetch revision notes for a chapter
  static Future<String> getChapterNotes(String subject, String chapter) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/notes/$chapter'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['notes'] ?? "No notes available.";
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chapter notes: $e');
      rethrow;
    }
  }

  // Trigger AI content generation from PDF
  static Future<Map<String, dynamic>> triggerContentGeneration({
    required String filename,
    required String subject,
    required String chapter,
    String bucketName = "Textbook",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/content/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'filename': filename,
          'subject': subject,
          'chapter': chapter,
          'bucket_name': bucketName,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to trigger generation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering content generation: $e');
      rethrow;
    }
  }

  // Trigger Bulk Generation for all PDFs in bucket
  static Future<Map<String, dynamic>> triggerBulkGeneration({
    String bucketName = "Textbook",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/content/generate-bulk?bucket_name=$bucketName'),
      ).timeout(const Duration(seconds: 5)); // Fast return (queued)
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to trigger bulk generation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering bulk generation: $e');
      rethrow;
    }
  }

  // Fetch mastery status for current student
  static Future<Map<String, dynamic>> getMasteryStatus() async {
    final studentId = currentUserId;
    if (studentId == null) return {};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/mastery/$studentId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (e) {
      print('Error fetching mastery: $e');
      return {};
    }
  }

  // Fetch diagnostic and chapter completion status
  static Future<Map<String, dynamic>> getDiagnosticStatus() async {
    final studentId = currentUserId;
    if (studentId == null) return {};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/check-diagnostic/$studentId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (e) {
      print('Error fetching diagnostic status: $e');
      return {};
    }
  }
}
