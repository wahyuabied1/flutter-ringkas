import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/auth_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);

    final emailController = TextEditingController(text: state.email);
    final passwordController = TextEditingController(text: state.password);

    ref.listen(authViewModelProvider, (previous, next) async {
      if (next.status == AuthStatus.success) {
        final prefs = await SharedPreferences.getInstance();
        final authData = next.authData;

        if (authData != null) {
          final token =
              authData['access_token'] ??
              authData['token'] ??
              authData['data']?['token'] ??
              '';

          if (token.isNotEmpty) {
            await prefs.setString('authToken', token);

            try {
              final userData = authData['data'] ?? authData['user'] ?? {};
              final userId = userData['id']?.toString() ?? '';
              final userName = userData['name'] ?? 'User';

              await prefs.setString('name', userName);
              await prefs.setString('userId', userId);
            } catch (_) {}
          }
        }

        if (!context.mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });

    Future<void> doLogin() async {
      FocusManager.instance.primaryFocus?.unfocus();

      await vm.loginUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.status == AuthStatus.loading ? null : doLogin,
                child: state.status == AuthStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
            ),
            if (state.status == AuthStatus.error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  state.errorMessage ?? "Login gagal",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
