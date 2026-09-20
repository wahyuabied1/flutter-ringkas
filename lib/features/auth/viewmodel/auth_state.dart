enum AuthStatus { initial, loading, success, error }

class AuthState {
  final String name;
  final String email;
  final String password;
  final String currencyCode;
  final AuthStatus status;
  final String? errorMessage;

  final Map<String, dynamic>? authData;

  const AuthState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.currencyCode = 'IDR',
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.authData,
  });

  AuthState copyWith({
    String? name,
    String? email,
    String? password,
    String? currencyCode,
    AuthStatus? status,
    String? errorMessage,
    Map<String, dynamic>? authData,
  }) {
    return AuthState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      currencyCode: currencyCode ?? this.currencyCode,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      authData: authData ?? this.authData,
    );
  }
}
