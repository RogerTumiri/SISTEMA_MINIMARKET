import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/models/auth_state.dart';

final dashboardDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final today = DateTime.now().toIso8601String().split('T')[0];
  final desde = '${today}T00:00:00.000Z';
  final hasta = '${today}T23:59:59.999Z';
  try {
    final results = await Future.wait([
      dio.get('${ApiConstants.reportes}/ventas', queryParameters: {'desde': desde, 'hasta': hasta}),
      dio.get('${ApiConstants.reportes}/inventario'),
      dio.get('${ApiConstants.cajas}/activa'),
    ]);
    return {
      'ventas': results[0].data['data'],
      'inventario': results[1].data['data'],
      'cajaActiva': results[2].data['data'],
    };
  } catch (_) {
    return {};
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final dataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false, floating: true,
            backgroundColor: AppColors.background, elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bienvenido, ${user?.nombreCompleto.split(' ').first ?? 'Usuario'}',
                  style: Theme.of(context).textTheme.headlineMedium),
                Text('${_greeting()} — ${_formatDate(DateTime.now())}',
                  style: Theme.of(context).textTheme.bodyMedium),
              ])),
              Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: cardShadow),
                child: IconButton(onPressed: () => ref.invalidate(dashboardDataProvider),
                  icon: const Icon(Icons.refresh, color: AppColors.primary), tooltip: 'Actualizar'),
              ),
              const SizedBox(width: 8),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: dataAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error cargando datos: $e'))),
              data: (data) => _buildContent(context, ref, data, user?.isAdmin ?? false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, WidgetRef ref, Map<String, dynamic> data, bool isAdmin) {
    final ventas = data['ventas'] as Map<String, dynamic>? ?? {};
    final inventario = data['inventario'] as Map<String, dynamic>? ?? {};
    final resV = ventas['resumen'] as Map<String, dynamic>? ?? {};
    final resI = inventario['resumen'] as Map<String, dynamic>? ?? {};
    final caja = data['cajaActiva'];
    final stockBajo = (resI['productos_bajo_minimo'] as num?)?.toInt() ?? 0;

    return SliverList(delegate: SliverChildListDelegate([
      GridView.count(
        crossAxisCount: MediaQuery.of(ctx).size.width > 900 ? 3 : 2,
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: MediaQuery.of(ctx).size.width > 900 ? 1.6 : 1.3,
        children: [
          _KpiCard(icon: Icons.attach_money_rounded, title: 'VENTAS HOY',
            value: 'Bs. ${_fmt(resV['monto_total'] ?? 0)}', sub: '${resV['total_ventas'] ?? 0} transacciones',
            iconBg: AppColors.accentPink, trend: '+5.2%'),
          _KpiCard(icon: Icons.trending_up_rounded, title: 'TICKET PROMEDIO',
            value: 'Bs. ${_fmt(resV['ticket_promedio'] ?? 0)}', sub: 'por venta hoy',
            iconBg: AppColors.accentOrange, trend: '+8.1%'),
          _KpiCard(icon: Icons.inventory_2_rounded, title: 'STOCK BAJO',
            value: '$stockBajo', sub: 'productos bajo mínimo',
            iconBg: stockBajo > 0 ? AppColors.warning : AppColors.accentGreen),
          _KpiCard(icon: caja != null ? Icons.lock_open_rounded : Icons.lock_rounded, title: 'CAJA',
            value: caja != null ? 'ABIERTA' : 'CERRADA',
            sub: caja != null ? 'Bs. ${_fmt(caja['monto_apertura'] ?? 0)} apertura' : 'Abrir caja para vender',
            iconBg: caja != null ? AppColors.accentGreen : AppColors.textHint),
        ],
      ),
      const SizedBox(height: 24),
      if (inventario['productos_criticos'] != null && (inventario['productos_criticos'] as List).isNotEmpty) ...[
        Row(children: [
          Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18)),
          const SizedBox(width: 10),
          const Text('Alertas de Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        _SectionCard(child: Column(children: [
          ...(inventario['productos_criticos'] as List).take(5).map((p) {
            final prod = p as Map<String, dynamic>;
            final estado = prod['estado'] as String? ?? 'BAJO';
            final c = estado == 'CRITICO' || estado == 'SIN_STOCK' ? AppColors.stockCritico : AppColors.stockBajo;
            return ListTile(
              leading: Container(width: 38, height: 38,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.warning_rounded, color: c, size: 18)),
              title: Text(prod['nombre'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Stock: ${prod['stock_actual']} / Mín: ${prod['stock_minimo']}', style: const TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(estado, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700))),
            );
          }),
        ])),
        const SizedBox(height: 24),
      ],
      if (ventas['top_productos'] != null && (ventas['top_productos'] as List).isNotEmpty) ...[
        const Text('Top Productos Hoy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _SectionCard(child: Column(children: [
          ...(ventas['top_productos'] as List).take(5).map((p) {
            final prod = p as Map<String, dynamic>;
            return ListTile(
              title: Text(prod['nombre_producto'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              subtitle: Text('${prod['cantidad']} unidades', style: const TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(20)),
                child: Text('Bs. ${_fmt(prod['monto'])}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13))),
            );
          }),
        ])),
      ],
    ]));
  }

  String _greeting() { final h = DateTime.now().hour; if (h < 12) return 'Buenos días'; if (h < 18) return 'Buenas tardes'; return 'Buenas noches'; }
  String _formatDate(DateTime d) { const days = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom']; const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic']; return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}'; }
  String _fmt(dynamic v) { if (v == null) return '0.00'; return (double.tryParse(v.toString()) ?? 0).toStringAsFixed(2); }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
    child: child);
}

class _KpiCard extends StatelessWidget {
  final IconData icon; final String title, value, sub; final Color iconBg; final String? trend;
  const _KpiCard({required this.icon, required this.title, required this.value, required this.sub, required this.iconBg, this.trend});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.5)),
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: iconBg.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconBg, size: 22)),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textHint), overflow: TextOverflow.ellipsis)),
          if (trend != null) ...[
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.trending_up, color: AppColors.accentGreen, size: 11),
                const SizedBox(width: 3),
                Text(trend!, style: const TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.w600)),
              ])),
          ],
        ]),
      ]),
    ]));
}
