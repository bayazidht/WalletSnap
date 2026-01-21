import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/providers/category_provider.dart';
import 'package:wallet_snap/providers/settings_provider.dart';
import 'package:wallet_snap/providers/theme_provider.dart';
import 'package:wallet_snap/services/auth_service.dart';
import 'package:wallet_snap/providers/transaction_provider.dart';
import 'package:wallet_snap/screens/wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ilarbaftbnvwfgqfghue.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsYXJiYWZ0Ym52d2ZncWZnaHVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5NjU1OTEsImV4cCI6MjA4NDU0MTU5MX0.hQBiicABgK0Tc5eMka6J4rtvdcwrJpy2LDcx5NJUXXs',
  );

  runApp(const WalletSnapApp());
}

class WalletSnapApp extends StatelessWidget {
  const WalletSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),

        StreamProvider<User?>(
          create: (context) => Supabase.instance.client.auth.onAuthStateChange
              .map((data) => data.session?.user),
          initialData: Supabase.instance.client.auth.currentUser,
          catchError: (_, __) => null,
        ),

        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProxyProvider<User?, TransactionProvider>(
          create: (context) => TransactionProvider(null),
          update: (context, user, previous) => TransactionProvider(user),
        ),

        ChangeNotifierProxyProvider<User?, CategoryProvider>(
          create: (context) => CategoryProvider(null),
          update: (context, user, previous) => CategoryProvider(user),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'WalletSnap',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorSchemeSeed: Colors.deepPurple,
              brightness: Brightness.light,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: Colors.deepPurple,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              useMaterial3: true,
            ),
            home: const Wrapper(),
          );
        },
      ),
    );
  }
}