import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/models/auth_state.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.isAdmin ?? false;
    final location = GoRouterState.of(context).matchedLocation;

    final navItems = <_NavItem>[
      const _NavItem('/dashboard', Icons.dashboard_outlined,    Icons.dashboard,       'Dashboard'),
      const _NavItem('/pos',       Icons.point_of_sale_outlined, Icons.point_of_sale,  'POS'),
      const _NavItem('/inventory', Icons.inventory_2_outlined,   Icons.inventory_2,    'Inventario'),
      const _NavItem('/products',  Icons.category_outlined,      Icons.category,       'Productos'),
      const _NavItem('/sales',     Icons.receipt_long_outlined, Icons.receipt_long,    'Ventas'),
      const _NavItem('/reports',   Icons.bar_chart,             Icons.bar_chart,       'Reportes'),
      if (isAdmin) ...[
        const _NavItem('/ai',      Icons.auto_awesome_outlined, Icons.auto_awesome,    'IA'),
        const _NavItem('/users',   Icons.people_outline,        Icons.people,          'Usuarios'),
        const _NavItem('/settings',Icons.settings_outlined,     Icons.settings,        'Config'),
      ],
    ];

    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWideScreen ? null : AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('🏪 MiniMarket Pro'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PopupMenuButton(
                child: Row(children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 32, height: 32,
                      child: Icon(Icons.person, color: AppColors.primary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(user.username, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                ]),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: () => ref.read(authProvider.notifier).logout(),
                    child: const Row(children: [
                      Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('Cerrar sesión'),
                    ]),
                  ),
                ],
              ),
            ),
        ],
      ),
      drawer: isWideScreen ? null : _Drawer(navItems: navItems, location: location, user: user),
      body: Row(children: [
        if (isWideScreen)
          _Sidebar(navItems: navItems, location: location, user: user),
        Expanded(child: child),
      ]),
      bottomNavigationBar: (isWideScreen || navItems.length > 5)
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex(navItems, location),
              onTap: (i) => context.go(navItems[i].path),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textHint,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              elevation: 0,
              items: navItems.map((n) => BottomNavigationBarItem(
                icon: Icon(n.iconOutline), activeIcon: Icon(n.iconFilled), label: n.label,
              )).toList(),
            ),
    );
  }

  int _currentIndex(List<_NavItem> items, String loc) {
    final idx = items.indexWhere((n) => loc.startsWith(n.path));
    return idx < 0 ? 0 : idx;
  }
}

class _Sidebar extends ConsumerWidget {
  final List<_NavItem> navItems;
  final String location;
  final dynamic user;
  const _Sidebar({required this.navItems, required this.location, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: const Center(child: Text('🏪', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MiniMarket',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Pro',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
            ),
          ]),
        ),

        // Menu label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('MENU',
              style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ),
        ),

        // Nav items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              ...navItems.take(6).map((n) => _buildNavItem(context, n)),
              if (navItems.length > 6) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Text('SUPPORT',
                    style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                ),
                ...navItems.skip(6).map((n) => _buildNavItem(context, n)),
              ],
            ],
          ),
        ),

        // User info + logout
        const Divider(height: 1),
        if (user != null)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user!.nombreCompleto ?? user!.username,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                  Text(user!.isAdmin ? 'Administrator' : 'Vendedor',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 18, color: AppColors.textHint),
                onPressed: () => ref.read(authProvider.notifier).logout(),
                tooltip: 'Cerrar sesión',
              ),
            ]),
          ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem n) {
    final selected = location.startsWith(n.path);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(n.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.sidebarActiveBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(
                selected ? n.iconFilled : n.iconOutline,
                color: selected ? AppColors.sidebarActiveText : AppColors.sidebarText,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(n.label,
                style: TextStyle(
                  color:      selected ? AppColors.sidebarActiveText : AppColors.sidebarText,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize:   14,
                ),
              ),
              if (selected) ...[
                const Spacer(),
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Drawer extends ConsumerWidget {
  final List<_NavItem> navItems;
  final String location;
  final dynamic user;
  const _Drawer({required this.navItems, required this.location, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
    backgroundColor: AppColors.sidebarBg,
    child: _Sidebar(navItems: navItems, location: location, user: user),
  );
}

class _NavItem {
  final String path;
  final IconData iconOutline;
  final IconData iconFilled;
  final String label;
  const _NavItem(this.path, this.iconOutline, this.iconFilled, this.label);
}
