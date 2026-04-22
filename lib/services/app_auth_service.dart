import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user_profile.dart';
import 'supabase_service.dart';

class AppAuthService {
  AppAuthService();

  static const String adminEmail = 'sandrodainez@hotmail.com';

  SupabaseClient? get _client => SupabaseService.instance.client;

  bool get isConfigured => SupabaseService.instance.isConfigured;
  bool get isReady => SupabaseService.instance.isReady;
  User? get currentUser => _client?.auth.currentUser;
  Session? get currentSession => _client?.auth.currentSession;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) return const Stream<AuthState>.empty();
    return client.auth.onAuthStateChange;
  }

  Future<void> initialize() async {
    await SupabaseService.instance.initialize();
  }

  Future<void> signIn({required String email, required String password}) async {
    await initialize();
    final client = _requireClient();
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await ensureCurrentUserProfile();
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await initialize();
    final client = _requireClient();
    final normalizedEmail = email.trim().toLowerCase();
    final response = await client.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {'full_name': fullName.trim()},
    );
    final user = response.user ?? client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Não foi possível concluir o cadastro.');
    }
    await _upsertProfile(
      userId: user.id,
      email: normalizedEmail,
      fullName: fullName.trim(),
    );
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<AppUserProfile?> fetchCurrentUserProfile() async {
    await initialize();
    final user = currentUser;
    if (user == null) return null;
    final client = _requireClient();
    final response = await client
        .from('app_users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (response == null) return null;
    return AppUserProfile.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<AppUserProfile?> ensureCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final existing = await fetchCurrentUserProfile();
    if (existing != null) return existing;
    await _upsertProfile(
      userId: user.id,
      email: user.email ?? '',
      fullName: (user.userMetadata?['full_name'] as String? ?? '').trim(),
    );
    return fetchCurrentUserProfile();
  }

  Future<List<AppUserProfile>> listUsers() async {
    await initialize();
    final client = _requireClient();
    final response = await client
        .from('app_users')
        .select()
        .order('created_at', ascending: false);
    if (response is! List) return const [];
    return response
        .map(
          (item) =>
              AppUserProfile.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> approveUser(String userId) async {
    await _updateUserStatus(userId: userId, status: AppUserStatus.active);
  }

  Future<void> blockUser(String userId) async {
    await _updateUserStatus(userId: userId, status: AppUserStatus.blocked);
  }

  Future<void> reactivateUser(String userId) async {
    await _updateUserStatus(userId: userId, status: AppUserStatus.active);
  }

  Future<void> _updateUserStatus({
    required String userId,
    required AppUserStatus status,
  }) async {
    await initialize();
    final client = _requireClient();
    final now = DateTime.now().toIso8601String();
    await client
        .from('app_users')
        .update({
          'status': status.code,
          'approved_at': status == AppUserStatus.active ? now : null,
          'blocked_at': status == AppUserStatus.blocked ? now : null,
          'updated_at': now,
        })
        .eq('id', userId);
  }

  Future<void> _upsertProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    final client = _requireClient();
    final normalizedEmail = email.trim().toLowerCase();
    final now = DateTime.now().toIso8601String();
    final isAdminUser = normalizedEmail == adminEmail;
    await client.from('app_users').upsert({
      'id': userId,
      'email': normalizedEmail,
      'full_name': fullName,
      'role': isAdminUser ? AppUserRole.admin.code : AppUserRole.clinician.code,
      'status': isAdminUser
          ? AppUserStatus.active.code
          : AppUserStatus.pending.code,
      'created_at': now,
      'updated_at': now,
      'approved_at': isAdminUser ? now : null,
      'blocked_at': null,
    }, onConflict: 'id');
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const AuthException(
        'Supabase não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }
}
