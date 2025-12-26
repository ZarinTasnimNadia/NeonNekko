import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:neonnekko/auth/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  void signUp() async {
    try {
      await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
        selectedGenres: <String>{},
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ShadToaster.of(context).show(const ShadToast(description: Text('Signup Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            ShadInput(controller: _usernameController, placeholder: const Text('Username')),
            const SizedBox(height: 16),
            ShadInput(controller: _emailController, placeholder: const Text('Email')),
            const SizedBox(height: 16),
            ShadInput(controller: _passwordController, placeholder: const Text('Password'), obscureText: true),
            const SizedBox(height: 32),
            ShadButton(onPressed: signUp, width: double.infinity, child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}