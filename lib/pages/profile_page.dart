import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isUploading = false;
  Map<String, dynamic>? _profileData;
  final _usernameController = TextEditingController();

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

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(image.path);
      final userId = _supabase.auth.currentUser!.id;
      
      final String extension = image.path.split('.').last.toLowerCase();
      final String path = '$userId/profile.$extension';

      await _supabase.storage.from('avatars').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      final String timestampedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('users').update({'avatar_url': timestampedUrl}).eq('id', userId);

      await _fetchProfile();
      
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Photo updated!')));
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('users').update({
        'username': _usernameController.text,
      }).eq('id', userId);
      
      await _fetchProfile();
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Profile updated!')));
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Error: $e')));
      }
    }
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
              onTap: _isUploading ? null : _uploadAvatar,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.muted,
                    ),
                    child: ClipOval(
                      child: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? Image.network(
                              avatarUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, size: 60, color: theme.colorScheme.primary);
                              },
                            )
                          : Icon(Icons.person, size: 60, color: theme.colorScheme.primary),
                    ),
                  ),
                  if (_isUploading) CircularProgressIndicator(color: theme.colorScheme.primary),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
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
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            ShadInput(
              controller: _usernameController,
              placeholder: const Text('Enter your username'),
            ),
            const SizedBox(height: 16),
            ShadButton(
              width: double.infinity,
              onPressed: _updateProfile,
              child: const Text('Save Profile Changes'),
            ),
            const Divider(height: 64),
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