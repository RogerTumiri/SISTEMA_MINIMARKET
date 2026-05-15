import 'usuario_model.dart';

// Since we can't run build_runner, using a simple sealed class approach
sealed class AuthState {
  const AuthState();
  const factory AuthState.initial()     = AuthInitial;
  const factory AuthState.loading()     = AuthLoading;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  factory AuthState.authenticated({required UsuarioModel user, required String token}) = AuthAuthenticated;
  factory AuthState.error(String message) = AuthError;

  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isLoading        => this is AuthLoading || this is AuthInitial;
}

final class AuthInitial          extends AuthState { const AuthInitial(); }
final class AuthLoading          extends AuthState { const AuthLoading(); }
final class AuthUnauthenticated  extends AuthState { const AuthUnauthenticated(); }
final class AuthAuthenticated    extends AuthState {
  final UsuarioModel user;
  final String token;
  AuthAuthenticated({required this.user, required this.token});
}
final class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
