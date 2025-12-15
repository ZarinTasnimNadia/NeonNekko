import 'package:flutter/material.dart';
import 'package:neonnekko/auth/auth_gate.dart';
import 'package:neonnekko/theme/theme_service.dart';
import 'package:provider/provider.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';


const String SUPABASE_URL = 'https://jzkkonmopoffhychcope.supabase.co'; 

const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp6a2tvbm1vcG9mZmh5Y2hjb3BlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MzQ0MTMsImV4cCI6MjA4MTIxMDQxM30.3p-5FgXsp-xDSscOhCijay3CPyLBzRMS7u_RUkCdGc4'; 

const String DEEPLINK_REDIRECT_URL = 'com.neonnekko.app://login-callback'; 


void main() async {
  
  WidgetsFlutterBinding.ensureInitialized(); 

  
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(
    
    ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: const NeonNekkoApp(), 
    ),
  );
}

class NeonNekkoApp extends StatelessWidget {
  const NeonNekkoApp({super.key}); 

  @override
  Widget build(BuildContext context) {

    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeonNeko Anime Tracker',
      theme: themeService.currentTheme,
      home: const AuthGate(), 
    );
  }
}