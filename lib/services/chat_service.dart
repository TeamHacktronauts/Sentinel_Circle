import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String endpoint = 'https://mxtuvmnpetwhdgcfefbf.supabase.co/functions/v1/chat-proxy';
  final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? ''; // JWT token from .env

  Future<String> sendMessage(String message, String userId) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $anonKey',
      },
      body: jsonEncode({
        'message': message,
        'user_id': userId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['reply'] != null) {
      return data['reply'];
    } else {
      return "Oops, something went wrong. Please try again.";
    }
  }
}
