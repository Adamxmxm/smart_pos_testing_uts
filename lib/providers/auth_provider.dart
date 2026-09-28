import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/user_profile_model.dart';
import '../services/supabase_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserProfileModel? userProfile;
  final String? errorMessage;

  const AuthState({
    this.isLoading = true, // start loading until session is resolved
    this.isAuthenticated = false,
    this.userProfile,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserProfileModel? userProfile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _service;
  StreamSubscription<sb.AuthState>? _authSub;

  AuthNotifier(this._service) : super(const AuthState(isLoading: true)) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authSub = _service.authStateChanges.listen((event) async {
      final session = event.session;
      final user = session?.user;

      if (event.event == sb.AuthChangeEvent.signedOut || user == null) {
        if (mounted) {
          state = const AuthState(isLoading: false, isAuthenticated: false);
        }
      } else if (event.event == sb.AuthChangeEvent.signedIn || event.event == sb.AuthChangeEvent.initialSession || event.event == sb.AuthChangeEvent.tokenRefreshed) {
        if (mounted) {
          state = state.copyWith(isLoading: true);
        }
        try {
          final profile = await _service.fetchCurrentProfile();
          if (mounted) {
            state = AuthState(
              isLoading: false,
              isAuthenticated: true,
              userProfile: profile,
            );
          }
        } catch (e) {
          debugPrint('Auth listener profile fetch error: $e');
          if (mounted) {
            state = const AuthState(isLoading: false, isAuthenticated: false);
          }
        }
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.signIn(email, password);
      // Let the stream listener update the authenticated state!
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _cleanError(e.toString()),
        );
      }
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.signUp(email, password, fullName);
      await _service.signOut(); // Ensure they have to log in manually
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _cleanError(e.toString()),
        );
      }
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.signOut();
    } catch (e) {
      debugPrint('signOut error: $e');
      if (mounted) {
        state = const AuthState(isLoading: false, isAuthenticated: false);
      }
    }
  }

  String _cleanError(String raw) =>
      raw.replaceAll('Exception:', '').trim();

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(SupabaseService.instance);
});
