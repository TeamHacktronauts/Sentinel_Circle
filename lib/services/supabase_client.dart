import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabase = SupabaseClient(
  'https://mxtuvmnpetwhdgcfefbf.supabase.co', // PROJECT_URL
  dotenv.env['SUPABASE_ANON_KEY'] ?? '', // publishable key from .env
);
