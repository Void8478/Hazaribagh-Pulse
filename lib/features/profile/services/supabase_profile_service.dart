import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hazaribagh_pulse/models/review_model.dart';
import 'package:hazaribagh_pulse/models/user_model.dart';

class SupabaseProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const Set<String> _allowedProfileColumns = {
    'id',
    'full_name',
    'username',
    'bio',
    'avatar_url',
    'location',
    'created_at',
    'updated_at',
  };

  String? _normalizedString(
    Object? value, {
    bool allowEmpty = false,
  }) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty && !allowEmpty) return null;
    return text;
  }

  Map<String, dynamic> _buildProfileDataForUser(
    User user, {
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? location,
    bool includeId = false,
    bool includeCreatedAt = false,
  }) {
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{};

    void putString(
      String key,
      Object? value, {
      bool allowEmpty = false,
      bool includeEmpty = false,
    }) {
      if (!_allowedProfileColumns.contains(key)) return;

      final normalized = _normalizedString(value, allowEmpty: allowEmpty);
      if (normalized != null) {
        data[key] = normalized;
      } else if (includeEmpty) {
        data[key] = '';
      }
    }

    if (includeId) {
      data['id'] = user.id;
    }

    putString(
      'full_name',
      fullName ?? user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
    );
    putString('username', username ?? user.userMetadata?['username']);
    putString(
      'bio',
      bio ?? user.userMetadata?['bio'],
      allowEmpty: true,
      includeEmpty: true,
    );
    putString(
      'avatar_url',
      avatarUrl ?? user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
      allowEmpty: true,
      includeEmpty: true,
    );
    putString(
      'location',
      location ?? user.userMetadata?['location'],
      allowEmpty: true,
      includeEmpty: true,
    );

    if (includeCreatedAt) {
      data['created_at'] = now;
    }
    data['updated_at'] = now;

    return data;
  }

  Map<String, dynamic> _sanitizeProfileUpdate(
    Map<String, dynamic> data, {
    bool includeUpdatedAt = true,
  }) {
    final sanitized = <String, dynamic>{};

    void putMapped(
      String key,
      Object? value, {
      bool allowEmpty = false,
      bool includeEmpty = false,
    }) {
      if (!_allowedProfileColumns.contains(key)) return;

      final normalized = _normalizedString(value, allowEmpty: allowEmpty);
      if (normalized != null) {
        sanitized[key] = normalized;
      } else if (includeEmpty) {
        sanitized[key] = '';
      }
    }

    putMapped(
      'full_name',
      data.containsKey('full_name') ? data['full_name'] : data['fullName'],
    );
    putMapped(
      'username',
      data.containsKey('username') ? data['username'] : data['userName'],
    );
    putMapped('bio', data['bio'], allowEmpty: true, includeEmpty: true);
    putMapped(
      'avatar_url',
      data.containsKey('avatar_url') ? data['avatar_url'] : data['avatarUrl'],
      allowEmpty: true,
      includeEmpty: true,
    );
    putMapped(
      'location',
      data['location'],
      allowEmpty: true,
      includeEmpty: true,
    );

    if (includeUpdatedAt) {
      sanitized['updated_at'] = DateTime.now().toIso8601String();
    }

    return sanitized;
  }

  Future<void> _createProfileIfMissing(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null || currentUser.id != userId) return;

    final insertData = _buildProfileDataForUser(
      currentUser,
      includeId: true,
      includeCreatedAt: true,
    );

    insertData.addAll(updateData);
    await _supabase.from('profiles').insert(insertData);
  }

  Future<UserModel?> ensureProfileForCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) {
      return UserModel.fromProfile(
        Map<String, dynamic>.from(existing),
        email: user.email ?? '',
      );
    }

    final created = await _supabase
        .from('profiles')
        .insert(
          _buildProfileDataForUser(
            user,
            includeId: true,
            includeCreatedAt: true,
          ),
        )
        .select()
        .single();

    return UserModel.fromProfile(
      Map<String, dynamic>.from(created),
      email: user.email ?? '',
    );
  }

  Future<UserModel> getUserProfile(String userId) async {
    try {
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();
      final currentUser = _supabase.auth.currentUser;
      return UserModel.fromProfile(
        Map<String, dynamic>.from(data),
        email: currentUser?.id == userId ? currentUser?.email ?? '' : '',
      );
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, profiles(id, full_name, username, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((data) => ReviewModel.fromJson(Map<String, dynamic>.from(data as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final updateData = _sanitizeProfileUpdate(data);
      if (updateData.length == 1 && updateData.containsKey('updated_at')) {
        return;
      }

      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        await _createProfileIfMissing(userId, updateData);
        return;
      }

      await _supabase.from('profiles').update(updateData).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> deleteUserData(String userId) async {
    try {
      await _supabase.rpc('delete_user_account');
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}
