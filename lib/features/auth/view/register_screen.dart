import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/auth_viewmodel.dart';

class RegisterAccountScreen extends ConsumerWidget {
  const RegisterAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    void goToNextStep() {
      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Harap isi semua data")));
        return;
      }

      ref
          .read(authViewModelProvider.notifier)
          .updateAccountDetails(
            nameController.text,
            emailController.text,
            passwordController.text,
          );

      Navigator.of(context).pushNamed('/register-currency');
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Buat Akun (1/3)")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Tambah Akun",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text("Bagaimana kamu ingin memberi nama akunmu?"),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Nama"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: "Email"),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: goToNextStep,
            child: const Text("Berikutnya"),
          ),
        ],
      ),
    );
  }
}
