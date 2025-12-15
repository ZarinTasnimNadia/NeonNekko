import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; 
import 'dart:convert'; 

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signIn(String loginIdentifier, String password) async {
    
    String finalEmail = loginIdentifier.trim(); 

    if (!finalEmail.contains('@')) {
      
      String? foundEmail;
      
      try {
        final response = await _supabase.rpc(
            'get_email_by_username',
            params: {'username_to_find': finalEmail}
        );
        
        if (response is List && response.isNotEmpty) {
          foundEmail = response[0] as String?;
        } else if (response is String) {
          foundEmail = response;
        } else {
          foundEmail = null;
        }

      } on PostgrestException catch (e) {
         print('RPC ERROR: Database error during username lookup: $e'); 
         throw Exception('Login failed due to a server configuration issue. Please contact support.');
      }
      
      if (foundEmail == null || foundEmail.isEmpty) {
        throw Exception('Invalid login credentials');
      }
      
      finalEmail = foundEmail;
    }

    try {
      await _supabase.auth.signInWithPassword(
        email: finalEmail,
        password: password,
      );
    } on AuthException catch (e) {
       throw Exception(e.message);
    }
  }

  Future<void> signUp({
    required String email, 
    required String password,
    required String username,
    String? fullName,
    String? dateOfBirth,
    required Set<String> selectedGenres,
  }) async {
    try {

      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      
      if (user == null) {
         throw Exception('Sign up failed: User could not be created.');
      }

      await _supabase.from('pending_profiles').insert({
        'id': user.id, 
        'username': username,
        'email': email,
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'selected_genres': selectedGenres.toList(), 
      });
      
      throw Exception('User created successfully. Please check your email to verify your account.');

      
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      print('>>> SUPABASE SIGNUP FAILED WITH RAW ERROR: $e');


      if (e.toString().contains('User created successfully. Please check your email')) {
          rethrow;
      }
      if (e.toString().contains('duplicate key value')) {
          throw Exception('Sign up failed: Username or Email already exists.');
      }
      
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}