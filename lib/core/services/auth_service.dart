import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Real Supabase Auth Service
/// Handles email/password auth, Google OAuth, and session management
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  static const int _authRetryAttempts = 3;
  static const Duration _authRetryBaseDelay = Duration(milliseconds: 600);

  bool _isTransientUpstreamTimeout(Object error) {
    if (error is TimeoutException) return true;

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      final status = error.statusCode;

      // Seen in the wild for temporary proxy/auth service issues.
      // ignore: unrelated_type_equality_checks
      if (status == 502 || status == 503 || status == 504) return true;
      if (msg.contains('upstream request timeout')) return true;
      if (msg.contains('gateway timeout')) return true;
      if (msg.contains('timeout')) return true;
    }

    final msg = error.toString().toLowerCase();
    if (msg.contains('upstream request timeout')) return true;
    if (msg.contains('gateway timeout')) return true;
    if (msg.contains('timeout')) return true;

    return false;
  }

  Future<T> _retryAuth<T>(Future<T> Function() action) async {
    Object? lastError;

    for (var attempt = 1; attempt <= _authRetryAttempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;

        if (!_isTransientUpstreamTimeout(e) || attempt == _authRetryAttempts) {
          rethrow;
        }

        // Simple exponential backoff (no jitter to keep deterministic behavior).
        final backoffMs = _authRetryBaseDelay.inMilliseconds * (1 << (attempt - 1));
        await Future<void>.delayed(Duration(milliseconds: backoffMs));
      }
    }

    // Defensive fallback; should be unreachable.
    throw lastError ?? StateError('Auth retry failed');
  }

  // ===================== Auth State =====================

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Current session
  Session? get currentSession => _client.auth.currentSession;

  /// Current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // ===================== Email/Password Auth =====================

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );

    // Create profile in profiles table if signup successful
    if (response.user != null && fullName != null) {
      await _createProfile(response.user!.id, fullName, email);
    }

    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _retryAuth(() async {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update password (when user is logged in)
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ===================== Google OAuth =====================

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      final redirectUrl = kIsWeb
          ? Uri.base.origin
          : 'io.supabase.medisync://login-callback';

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      return true;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  // ===================== Sign Out =====================

  /// Sign out current user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ===================== Profile Management =====================

  /// Create user profile in database
  Future<void> _createProfile(
    String userId,
    String fullName,
    String email,
  ) async {
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'email': email,
        'role': 'doctor', // Default role
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Profile creation error: $e');
      // Non-fatal - user can still use the app
    }
  }

  /// Get current user profile from database
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get profile error: $e');
      // Return basic info from auth if profile doesn't exist
      return {
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? 'User',
        'role': 'doctor',
      };
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? role,
    String? specialty,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (role != null) updates['role'] = role;
    if (specialty != null) updates['specialty'] = specialty;

    await _client.from('profiles').update(updates).eq('id', user.id);

    // Also update auth metadata
    if (fullName != null) {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
    }
  }
}
