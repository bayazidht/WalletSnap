import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/screens/auth/sign_in_screen.dart';
import 'package:wallet_snap/screens/home/base_scaffold.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<User?>(context);

    if (user != null) {
      return const BaseScaffold();
    } else {
      return const SignInScreen();
    }
  }
}