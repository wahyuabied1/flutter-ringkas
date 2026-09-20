import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import 'auth_state.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel(ref.watch(apiServiceProvider));
});

class AuthViewModel extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthViewModel(this._apiService) : super(const AuthState());

  // STEP 1: SIMPAN NAME, EMAIL, PASSWORD
  void updateAccountDetails(String name, String email, String password) {
    state = state.copyWith(name: name, email: email, password: password);
  }

  // STEP 2: SIMPAN CURRENCY
  void updateCurrency(String currencyCode) {
    state = state.copyWith(currencyCode: currencyCode);
  }

  // STEP 3: REGISTER USER KE TABEL USER
  Future<void> registerAndLogin(
    String walletName,
    double initialBalance,
  ) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      // Daftar user (simpan ke tabel user)
      final registerResult = await _apiService.registerUser(
        name: state.name,
        email: state.email,
        password: state.password,
      );

      // Ambil token dari response
      final token = registerResult['access_token'] ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan di response register');
      }

      // STEP 3.5: FETCH USER DATA menggunakan token baru
      final userResponse = await _apiService.getCurrentUser(token: token);

      final userId = userResponse['id'];

      if (userId == null) {
        throw Exception('UserId tidak ditemukan di user response');
      }

      // STEP 4: BUAT DOMPET KE TABEL DOMPET
      await _apiService.createWallet(
        userId: userId,
        name: walletName,
        currencyCode: state.currencyCode,
        initialBalance: initialBalance,
        token: token,
      );

      state = state.copyWith(
        status: AuthStatus.success,
        authData: registerResult,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ✅ LOGIN USER
  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final result = await _apiService.loginUser(
        email: email,
        password: password,
      );

      final user = result['user'] ?? {};

      state = state.copyWith(
        status: AuthStatus.success,
        authData: result,
        name: user['name'] ?? state.name,
        email: user['email'] ?? email,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
