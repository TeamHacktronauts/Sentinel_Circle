import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatService {
  final String endpoint = '${dotenv.env['SUPABASE_URL']}/functions/v1/chat-proxy';
  final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? ''; // JWT token from .env

  Future<String> sendMessage(
    String message, 
    String userId, {
    List<File>? imageFiles,
  }) async {
    // Convert images to base64 if provided
    List<String>? base64Images;
    if (imageFiles != null && imageFiles.isNotEmpty) {
      base64Images = [];
      for (final imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        base64Images.add(base64Encode(bytes));
      }
    }

    // For now, we'll handle base64 image and note that URL-based files
    // would need to be uploaded to a storage service first
    // This is a simplified implementation - in production, you'd upload
    // files to cloud storage and send URLs

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $anonKey',
      },
      body: jsonEncode({
        'message': message,
        'user_id': userId,
        if (base64Images != null) 'images': base64Images,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['reply'] != null) {
      return data['reply'];
    } else {
      return "Oops, something went wrong. Please try again.";
    }
  }

  // Helper method to determine file type
  String getFileType(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return 'image';
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return 'video';
      case 'pdf':
        return 'pdf';
      default:
        return 'unknown';
    }
  }
}
