import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  SupabaseClient? _client;
  bool _initialized = false;

  bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;
  bool get isReady => isConfigured && _initialized && _client != null;

  Future<void> initialize() async {
    if (!isConfigured || _initialized) return;
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      authCallbackUrlHostname: 'login-callback',
    );
    _client = Supabase.instance.client;
    _initialized = true;
  }

  SupabaseClient? get client => _client;
}
