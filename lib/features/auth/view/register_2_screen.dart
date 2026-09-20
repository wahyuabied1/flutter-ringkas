import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/auth_viewmodel.dart';

class RegisterCurrencyScreen extends ConsumerStatefulWidget {
  const RegisterCurrencyScreen({super.key});

  @override
  ConsumerState<RegisterCurrencyScreen> createState() =>
      _RegisterCurrencyScreenState();
}

class _RegisterCurrencyScreenState
    extends ConsumerState<RegisterCurrencyScreen> {
  String _selectedCurrency = 'IDR';

  void goToNextStep() {
    ref.read(authViewModelProvider.notifier).updateCurrency(_selectedCurrency);
    Navigator.of(context).pushNamed('/register-balance');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mata Uang (2/3)")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Pilih Mata Uang",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text("Gunakan mata uang yang kamu pakai sehari-hari."),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            items: ['IDR', 'USD', 'EUR', 'JPY']
                .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCurrency = value;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: "Mata Uang",
              border: OutlineInputBorder(),
            ),
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
