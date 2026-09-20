import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodel/auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';

class RegisterBalanceScreen extends ConsumerWidget {
  const RegisterBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletNameController = TextEditingController(text: 'Dompet Saya');
    final balanceController = TextEditingController(text: '0');

    ref.listen(authViewModelProvider, (previous, next) async {
      if (next.status == AuthStatus.success) {
        // ✅ Ambil saldo yang dimasukkan user dari TextField
        final double balance = double.tryParse(balanceController.text) ?? 0.0;

        // ✅ Simpan data ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('initialBalance', balance);

        // Simpan token dan nama user untuk home screen
        final authData = next.authData;
        if (authData != null) {
          final token = authData['access_token'] ?? '';
          // Coba ambil dari 'data' atau 'user' field (support kedua format)
          final userData = authData['data'] ?? authData['user'] ?? {};
          final userName = userData['name'] ?? 'User';
          final userId = userData['id'] ?? '';

          await prefs.setString('authToken', token);
          await prefs.setString('name', userName);
          await prefs.setString('userId', userId.toString());
        }

        // ✅ Cek context tetap aman
        if (!context.mounted) return;

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (next.status == AuthStatus.error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? "Terjadi kesalahan")),
        );
      }
    });

    void finishRegistration() {
      final String walletName = walletNameController.text.isEmpty
          ? 'Dompet Saya'
          : walletNameController.text;
      final double balance = double.tryParse(balanceController.text) ?? 0.0;
      ref
          .read(authViewModelProvider.notifier)
          .registerAndLogin(walletName, balance);
    }

    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Dompet & Saldo Awal (3/3)")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Buat Dompet Pertamamu",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text("Berikan nama dompet dan saldo awalmu."),
          const SizedBox(height: 24),
          TextField(
            controller: walletNameController,
            decoration: const InputDecoration(
              labelText: "Nama Dompet",
              hintText: "Contoh: Dompet Harian, Tabungan, dll",
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: balanceController,
            decoration: const InputDecoration(
              labelText: "Saldo Awal",
              prefixText: "Rp ",
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (authState.status == AuthStatus.loading)
                ? null
                : finishRegistration,
            child: (authState.status == AuthStatus.loading)
                ? const CircularProgressIndicator()
                : const Text("Selesai"),
          ),
        ],
      ),
    );
  }
}
