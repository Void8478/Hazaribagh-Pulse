import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../services/supabase_content_creation_service.dart';
import '../services/supabase_media_service.dart';

final mediaServiceProvider = Provider<SupabaseMediaService>((ref) {
  return SupabaseMediaService(ref.watch(supabaseClientProvider));
});

final contentCreationServiceProvider =
    Provider<SupabaseContentCreationService>((ref) {
  return SupabaseContentCreationService(ref.watch(supabaseClientProvider));
});
