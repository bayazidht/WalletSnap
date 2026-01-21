import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  Stream<User?> get user => _supabase.auth.onAuthStateChange.map((data) => data.session?.user);

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Sign Up Error: $e');
      }
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Sign In Error: $e');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      rethrow;
    }
  }

  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}