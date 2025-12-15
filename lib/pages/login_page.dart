import 'package:flutter/material.dart';
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

  void login() async{

    final loginIdentifier = _identifierController.text.trim();
    final password = _passwordController.text;

    try {
      await authService.signIn(loginIdentifier, password);
    }
    catch (e) {
      if (mounted) {

        String errorMessage = e.toString().contains('Invalid login credentials') 
            ? 'Login failed: Invalid username/email or password.' 
            : 'Login failed: An unexpected error occurred.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red, 
          ),
        );
      }
    }
  } 
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeonNeko Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(

              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'e.g. user@email.com',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () { 
                  },
                  child: const Text('Forgotten Password'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  child: const Text('Sign up'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: login,
                child: const Text('Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}