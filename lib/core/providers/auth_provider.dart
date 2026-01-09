import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth State Provider - Reactive stream of auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

/// Is Authenticated Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// User Profile Provider - Fetches profile from database
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return null;

  return await authService.getCurrentProfile();
});

/// Auth Error State - Using NotifierProvider pattern for Riverpod 3.x
class AuthErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? error) => state = error;
  void clear() => state = null;
}

final authErrorProvider = NotifierProvider<AuthErrorNotifier, String?>(
  () => AuthErrorNotifier(),
);

/// Auth Notifier - Handles auth actions with loading/error states
class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AuthService get _authService => ref.read(authServiceProvider);

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    ref.read(authErrorProvider.notifier).clear();

    try {
      await _authService.signInWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      final error = switch (e) {
        AuthException() => e.statusCode != null
            ? 'Sign in failed (${e.statusCode}): ${e.message}'
            : e.message,
        _ => e.toString(),
      };
      ref.read(authErrorProvider.notifier).setError(error);
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    state = const AsyncValue.loading();
    ref.read(authErrorProvider.notifier).clear();

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user == null) {
        ref.read(authErrorProvider.notifier).setError('Registration failed');
        state = const AsyncValue.data(null);
        return false;
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      final error = e is AuthException ? e.message : 'Registration failed';
      ref.read(authErrorProvider.notifier).setError(error);
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    ref.read(authErrorProvider.notifier).clear();

    try {
      final success = await _authService.signInWithGoogle();
      state = const AsyncValue.data(null);
      return success;
    } catch (e) {
      ref.read(authErrorProvider.notifier).setError('Google sign-in failed');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    ref.read(authErrorProvider.notifier).clear();

    try {
      await _authService.resetPassword(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      final error = e is AuthException ? e.message : 'Password reset failed';
      ref.read(authErrorProvider.notifier).setError(error);
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

/// Auth Notifier Provider
final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(
  () => AuthNotifier(),
);
