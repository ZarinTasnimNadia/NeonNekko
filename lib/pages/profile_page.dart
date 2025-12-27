import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  final _usernameController = TextEditingController();

  final List<String> _avatarOptions = List.generate(
    20,
    (index) => 'https://api.dicebear.com/7.x/big-smile/svg?seed=Neko$index',
  );

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final currentUserId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('users').select().eq('id', currentUserId).single();
      if (mounted) {
        setState(() {
          _profileData = data;
          _usernameController.text = data['username'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _updateAvatar(String url) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('users').update({'avatar_url': url}).eq('id', userId);
      
      if (mounted) {
        setState(() {
          _profileData?['avatar_url'] = url;
        });
        Navigator.pop(context);
        ShadToaster.of(context).show(const ShadToast(description: Text('Avatar updated!')));
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Database error: $e')));
      }
    }
  }

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
                    onTap: () => _updateAvatar(_avatarOptions[index]),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.muted,
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = ShadTheme.of(context);
    final String? avatarUrl = _profileData?['avatar_url'];

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showAvatarPicker,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.muted,
                      border: Border.all(color: theme.colorScheme.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? SvgPicture.network(avatarUrl, fit: BoxFit.cover)
                          : Icon(Icons.person, size: 70, color: theme.colorScheme.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            ShadInput(controller: _usernameController, placeholder: const Text('Enter username')),
            const SizedBox(height: 20),
            ShadButton(
              width: double.infinity,
              onPressed: () async {
                final userId = _supabase.auth.currentUser!.id;
                await _supabase.from('users').update({'username': _usernameController.text}).eq('id', userId);
                await _fetchProfile();
                if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Saved!')));
              },
              child: const Text('Save Profile Changes'),
            ),
            const Divider(height: 60),
            ShadButton.destructive(
              width: double.infinity,
              onPressed: () async {
                await _supabase.auth.signOut();
                if (mounted) Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}