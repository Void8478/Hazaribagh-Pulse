import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the global Supabase client instance safely through Riverpod.
/// This allows for easier mocking and testing if needed, while centralizing
/// the access point to the Supabase backend.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
