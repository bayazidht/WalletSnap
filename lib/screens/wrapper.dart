import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:wallet_snap/services/auth_service.dart';
import 'package:wallet_snap/screens/auth/sign_in_screen.dart';
import 'package:wallet_snap/screens/home/base_scaffold.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return const BaseScaffold();
        } else {
          return const SignInScreen();
        }
      },
    );
  }
}