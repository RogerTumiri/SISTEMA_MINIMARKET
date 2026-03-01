import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_state.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(_userCtrl.text.trim(), _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) context.go('/dashboard');
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            colors: [Color(0xFF2A55C4), Color(0xFF3B6FF0), Color(0xFF6B9FF8)],
            stops:  [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Logo
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('🏪', style: TextStyle(fontSize: 28))),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MiniMarket Pro',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Gestión Inteligente de Inventarios',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 36),

              // Card
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 40, offset: const Offset(0, 16)),
                  ],
                ),
                padding: const EdgeInsets.all(36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Iniciar Sesión',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ingresa tus credenciales para continuar',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Error message
                      if (authState is AuthError)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color:        AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border:       Border.all(color: AppColors.error.withOpacity(0.25)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                (authState as AuthError).message,
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ]),
                        ),

                      // Usuario
                      TextFormField(
                        controller:    _userCtrl,
                        keyboardType:  TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText:  'Usuario o Email',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 14),

                      // Contraseña
                      TextFormField(
                        controller:     _passCtrl,
                        obscureText:    _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText:  'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 6),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Login button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Ingresar al Sistema',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              Text(
                '© 2025 MiniMarket Pro · v1.0.0',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
