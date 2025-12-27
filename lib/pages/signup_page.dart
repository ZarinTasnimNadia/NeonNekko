import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  
  String? _selectedAvatarUrl;
  List<String> _selectedGenres = [];
  
  final List<String> _avatarOptions = List.generate(
    20,
    (index) => 'https://api.dicebear.com/7.x/big-smile/svg?seed=Neko$index',
  );

  final List<String> _availableGenres = [
    'Action', 'Adventure', 'Animation', 'Comedy', 'Drama', 
    'Fantasy', 'Horror', 'Mystery', 'Romance', 'Science Fiction', 
    'Thriller', 'Anime', 'Supernatural', 'Slice of Life'
  ];

  void _showAvatarPicker() {
    final theme = ShadTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select your Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarUrl = _avatarOptions[index]);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.muted,
                        border: Border.all(
                          color: _selectedAvatarUrl == _avatarOptions[index] 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.primary.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(child: SvgPicture.network(_avatarOptions[index])),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void signUp() async {
    try {
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
        avatarUrl: _selectedAvatarUrl,
        selectedGenres: _selectedGenres,
      );
      
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Success! Please check your email to verify.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text('Sign up'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showAvatarPicker,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.muted,
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                    ),
                    child: ClipOval(
                      child: (_selectedAvatarUrl != null)
                          ? SvgPicture.network(_selectedAvatarUrl!, fit: BoxFit.cover)
                          : Icon(Icons.person, size: 60, color: theme.colorScheme.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ShadInput(
              controller: _usernameController,
              placeholder: const Text('Username'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildFieldRow('Name:', _fullNameController),
            _buildFieldRow('Email:', _emailController),
            _buildGenreRow(),
            _buildFieldRow('Password:', _passwordController, obscureText: true),
            _buildFieldRow('Date of Birth:', _dobController, hint: 'YYYY-MM-DD'),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerRight,
              child: ShadButton(onPressed: signUp, child: const Text('Verify email')),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, TextEditingController controller, {bool obscureText = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: ShadInput(
              controller: controller,
              obscureText: obscureText,
              placeholder: hint != null ? Text(hint) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 100, child: Text('Genre:', style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: ShadSelect<String>.multiple(
              placeholder: const Text('choose genre'),
              options: _availableGenres.map((g) => ShadOption(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _selectedGenres = v.toList()),
              selectedOptionsBuilder: (context, values) => Text(values.join(', '), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}