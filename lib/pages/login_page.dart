import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:neonnekko/auth/auth_service.dart';
import 'package:neonnekko/pages/signup_page.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> { 
  final authService = AuthService();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  void login() async {
    try {
      await authService.signIn(_identifierController.text.trim(), _passwordController.text);
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(
          description: Text('Login failed. Please check your credentials.'),
        ));
      }
    }
  } 
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShadInput(controller: _identifierController, placeholder: const Text('Email')),
            const SizedBox(height: 16),
            ShadInput(controller: _passwordController, placeholder: const Text('Password'), obscureText: true),
            const SizedBox(height: 32),
            ShadButton(onPressed: login, width: double.infinity, child: const Text('Sign in')),
            ShadButton.ghost(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
              child: const Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}