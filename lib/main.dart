import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/app_theme.dart';
import 'data/services/api_service.dart';

// Auth
import 'features/auth/view/welcome_screen.dart';
import 'features/auth/view/login_screen.dart';
import 'features/auth/view/register_screen.dart';
import 'features/auth/view/register_2_screen.dart';
import 'features/auth/view/register_3_screen.dart';

// Other pages
import 'features/home/view/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

// Tambahkan import ini
import 'features/transaksi/view/add_transaction_screen.dart';
import 'features/transaksi/view/transaction_screen.dart';
import 'features/transaksi/view/detail_transaction_screen.dart';
import 'features/transaksi/view/search_screen.dart';
import 'features/profile/view/profile_screen.dart';
import 'features/ringkasan/view/ringkasan_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await openLocalDb();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RINGKAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Start di Welcome
      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),

        // Welcome
        '/welcome': (context) => const WelcomeScreen(),

        // Login
        '/login': (context) => const LoginScreen(),

        // Register steps
        '/register': (context) => const RegisterAccountScreen(),
        '/register-currency': (context) => const RegisterCurrencyScreen(),
        '/register-balance': (context) => const RegisterBalanceScreen(),

        // Home
        '/home': (context) => const HomeScreen(),

        // Transaction
        '/add-transaction': (context) => const AddTransactionScreen(),
        '/transaction': (context) => const TransactionScreen(),
        '/search': (context) => const SearchScreen(),

        // Ringkasan
        '/ringkasan': (context) => const RingkasanScreen(),

        // Profile
        '/profile': (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/transaction-detail/') ?? false) {
          final transactionId = settings.name!.replaceFirst(
            '/transaction-detail/',
            '',
          );
          return MaterialPageRoute(
            builder: (context) =>
                DetailTransactionScreen(transactionId: transactionId),
          );
        }
        return null;
      },
    );
  }
}
