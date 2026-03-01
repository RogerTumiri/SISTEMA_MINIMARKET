import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/products/presentation/screens/product_form_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/sales/presentation/screens/sales_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/ai/presentation/screens/ai_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../layout/main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn   = authState.isAuthenticated;
      final isLoginPage  = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn  && isLoginPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/dashboard', name: 'dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/pos',       name: 'pos',       builder: (_, __) => const PosScreen()),
          GoRoute(path: '/products',  name: 'products',  builder: (_, __) => const ProductsScreen(), routes: [
            GoRoute(
              path: 'new',
              name: 'product-new',
              builder: (_, __) => const ProductFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              name: 'product-edit',
              builder: (_, state) => ProductFormScreen(productId: state.pathParameters['id']),
            ),
          ]),
          GoRoute(path: '/inventory', name: 'inventory', builder: (_, __) => const InventoryScreen()),
          GoRoute(path: '/sales',     name: 'sales',     builder: (_, __) => const SalesScreen()),
          GoRoute(path: '/users',     name: 'users',     builder: (_, __) => const UsersScreen()),
          GoRoute(path: '/reports',   name: 'reports',   builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/ai',        name: 'ai',        builder: (_, __) => const AiScreen()),
          GoRoute(path: '/settings',  name: 'settings',  builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text('Página no encontrada: ${state.uri}'),
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Ir al inicio'),
          ),
        ]),
      ),
    ),
  );
});
