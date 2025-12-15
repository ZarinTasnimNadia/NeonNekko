import 'package:flutter/material.dart';
import 'package:neonnekko/auth/auth_service.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final authService = AuthService();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  
  DateTime? _selectedDate; 
  
  Set<String> _selectedGenres = {}; 
  
  final List<String> _genres = [
    'Action', 'Adventure', 'Comedy', 'Fantasy', 'Sci-Fi', 
    'Romance', 'Horror', 'Slice of Life', 'Mystery'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000), 
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor, 
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _showGenreDialog() async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return MultiSelectGenreDialog(
          allGenres: _genres,
          initialSelected: _selectedGenres,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedGenres = selected;
      });
    }
  }

  void signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();
    final fullName = _nameController.text.trim();
    final dateOfBirth = _dobController.text.isNotEmpty ? _dobController.text : null; 
    
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in Email, Password, and Username.')),
        );
      }
      return;
    }

    try {
      await authService.signUp(
        email: email, 
        password: password, 
        username: username,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        selectedGenres: _selectedGenres,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Please check your email to verify.')),
        );
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      if (mounted) {
        // FIX: Display the actual error message thrown by the AuthService
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: const Center(child: Text('choose photo')),
            ),
            const SizedBox(height: 8),
            
            Text(
              _usernameController.text.isEmpty ? 'Username' : _usernameController.text,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name:')),
            const SizedBox(height: 16),
            
            TextField(
              controller: _usernameController, 
              decoration: const InputDecoration(labelText: 'Username:'),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 16),
            
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email:')),
            const SizedBox(height: 16),
            
            _buildGenreSelectionButton(context),
            const SizedBox(height: 16),

            _buildDateField(context),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController, 
              decoration: const InputDecoration(labelText: 'Password:'), 
              obscureText: true,
            ),
            
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: signUp,
                child: const Text('Verify email'),
              ),
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreSelectionButton(BuildContext context) {
    return InkWell(
      onTap: _showGenreDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preferred Genres:', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _selectedGenres.isEmpty ? 'Tap to choose genres' : _selectedGenres.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            const Text('Date of Birth:', style: TextStyle(color: Colors.black54)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _dobController.text.isEmpty ? 'YYYY-MM-DD' : _dobController.text,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Multi-Select Dialog Class
class MultiSelectGenreDialog extends StatefulWidget {
  final List<String> allGenres;
  final Set<String> initialSelected;

  const MultiSelectGenreDialog({super.key, required this.allGenres, required this.initialSelected});

  @override
  State<MultiSelectGenreDialog> createState() => _MultiSelectGenreDialogState();
}

class _MultiSelectGenreDialogState extends State<MultiSelectGenreDialog> {
  late Set<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Preferred Genres'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.allGenres.map((genre) {
            return CheckboxListTile(
              activeColor: Theme.of(context).primaryColor,
              value: _selectedItems.contains(genre),
              title: Text(genre),
              onChanged: (isSelected) {
                setState(() {
                  if (isSelected == true) {
                    _selectedItems.add(genre);
                  } else {
                    _selectedItems.remove(genre);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), 
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedItems), 
          child: const Text('Done'),
        ),
      ],
    );
  }
}