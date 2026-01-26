import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/features/categories/data/category_model.dart';
import 'package:wallet_snap/core/theme/theme_provider.dart';
import 'package:wallet_snap/features/auth/ui/auth_gate.dart';

import 'features/settings/logic/settings_provider.dart';
import 'features/transactions/data/transaction_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionTypeAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CategoryTypeAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CategoryModelAdapter());

  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox('settings');

  await Supabase.initialize(
    url: 'https://ilarbaftbnvwfgqfghue.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsYXJiYWZ0Ym52d2ZncWZnaHVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5NjU1OTEsImV4cCI6MjA4NDU0MTU5MX0.hQBiicABgK0Tc5eMka6J4rtvdcwrJpy2LDcx5NJUXXs',
  );

  final container = ProviderContainer();
  try {
    await container.read(settingsProvider.notifier).loadSettings();
    await container.read(themeProvider.notifier).loadTheme();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const WalletSnapApp(),
    ),
  );
}

class WalletSnapApp extends ConsumerWidget {
  const WalletSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'WalletSnap',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
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
      home: const AuthGate(),
    );
  }
}