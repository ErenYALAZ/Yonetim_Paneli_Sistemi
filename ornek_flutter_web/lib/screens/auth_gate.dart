import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ornek_flutter_web/screens/home_screen.dart';
import 'package:ornek_flutter_web/screens/login_screen.dart';
import 'package:ornek_flutter_web/screens/main_layout_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const MainLayoutScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
} 