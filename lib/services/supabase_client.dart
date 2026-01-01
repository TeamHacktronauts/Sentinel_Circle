import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabase = SupabaseClient(
  dotenv.env['SUPABASE_URL'] ?? '', // PROJECT_URL from .env
  dotenv.env['SUPABASE_ANON_KEY'] ?? '', // publishable key from .env
);
