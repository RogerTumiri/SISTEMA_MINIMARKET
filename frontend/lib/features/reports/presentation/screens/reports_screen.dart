import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic> _ventasData = {};
  Map<String, dynamic> _invData = {};
  Map<String, dynamic> _ganancias = {};
  bool _loading = false;
  DateTime _desde = DateTime.now().copyWith(day: 1);
  DateTime _hasta = DateTime.now();

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    final desde = _desde.toIso8601String();
    final hasta = _hasta.copyWith(hour: 23, minute: 59, second: 59).toIso8601String();
    try {
      final results = await Future.wait([
        dio.get('${ApiConstants.reportes}/ventas', queryParameters: {'desde': desde, 'hasta': hasta}),
        dio.get('${ApiConstants.reportes}/inventario'),
        dio.get('${ApiConstants.reportes}/ganancias', queryParameters: {'desde': desde, 'hasta': hasta}),
      ]);
      setState(() {
        _ventasData = (results[0].data['data'] as Map<String, dynamic>?) ?? {};
        _invData = (results[1].data['data'] as Map<String, dynamic>?) ?? {};
        _ganancias = (results[2].data['data'] as Map<String, dynamic>?) ?? {};
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final resV = _ventasData['resumen'] as Map<String, dynamic>? ?? {};
    final resI = _invData['resumen'] as Map<String, dynamic>? ?? {};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false, title: const Text('Reportes'),
        bottom: TabBar(controller: _tabs, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Ventas'), Tab(text: 'Inventario'), Tab(text: 'Ganancias')]),
        actions: [
          TextButton.icon(icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            label: Text('${_fmtDate(_desde)} — ${_fmtDate(_hasta)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: _pickDateRange),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Colors.white)),
        ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [_buildVentasTab(resV), _buildInventarioTab(resI), _buildGananciasTab()]),
    );
  }

  Widget _buildVentasTab(Map<String, dynamic> resumen) {
    final topProductos = _ventasData['top_productos'] as List? ?? [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6, children: [
        _MetricCard('Total Ventas', '${resumen['total_ventas'] ?? 0}', Icons.shopping_bag_outlined, AppColors.primary),
        _MetricCard('Monto Total', 'Bs. ${_fmt(resumen['monto_total'])}', Icons.attach_money, AppColors.secondary),
        _MetricCard('Ticket Prom.', 'Bs. ${_fmt(resumen['ticket_promedio'])}', Icons.receipt_long, AppColors.accent),
        _MetricCard('Impuestos', 'Bs. ${_fmt(resumen['total_impuestos'])}', Icons.account_balance, AppColors.primary),
      ]),
      const SizedBox(height: 20),
      if ((resumen['por_metodo_pago'] as Map?)?.isNotEmpty == true) ...[
        const Text('Por Método de Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...(resumen['por_metodo_pago'] as Map).entries.map((e) => Card(child: ListTile(
          title: Text(e.key as String),
          trailing: Text('Bs. ${_fmt(e.value)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))))),
        const SizedBox(height: 16),
      ],
      if (topProductos.isNotEmpty) ...[
        const Text('Top Productos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...topProductos.take(10).map((p) {
          final prod = p as Map<String, dynamic>;
          return Card(child: ListTile(title: Text(prod['nombre_producto'] as String? ?? ''),
            subtitle: Text('${prod['total_cantidad']} unidades'),
            trailing: Text('Bs. ${_fmt(prod['total_monto'])}', style: const TextStyle(fontWeight: FontWeight.bold))));
        }),
      ],
    ]);
  }

  Widget _buildInventarioTab(Map<String, dynamic> resumen) {
    final criticos = _invData['productos_criticos'] as List? ?? [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6, children: [
        _MetricCard('Total Prod.', '${resumen['total_productos'] ?? 0}', Icons.category_outlined, AppColors.primary),
        _MetricCard('Valor Invt.', 'Bs. ${_fmt(resumen['valor_total_inventario'])}', Icons.account_balance_wallet, AppColors.secondary),
        _MetricCard('Bajo Mínimo', '${resumen['productos_bajo_minimo'] ?? 0}', Icons.warning_amber_outlined, AppColors.warning),
        _MetricCard('Sin Stock', '${resumen['productos_sin_stock'] ?? 0}', Icons.remove_shopping_cart, AppColors.error),
      ]),
      const SizedBox(height: 16),
      if (criticos.isNotEmpty) ...[
        const Text('Productos Críticos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...criticos.map((p) {
          final prod = p as Map<String, dynamic>;
          final est = prod['estado'] as String? ?? 'BAJO';
          final c = est == 'CRITICO' || est == 'SIN_STOCK' ? AppColors.error : AppColors.warning;
          return Card(child: ListTile(leading: Icon(Icons.warning_outlined, color: c),
            title: Text(prod['nombre'] as String? ?? ''),
            subtitle: Text('Stock: ${prod['stock_actual']} / Mín: ${prod['stock_minimo']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(est, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)))));
        }),
      ],
    ]);
  }

  Widget _buildGananciasTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6, children: [
        _MetricCard('Ventas Total', 'Bs. ${_fmt(_ganancias['ventas_total'])}', Icons.trending_up, AppColors.primary),
        _MetricCard('Costo Total', 'Bs. ${_fmt(_ganancias['costo_total'])}', Icons.trending_down, AppColors.error),
        _MetricCard('Ganancia Bruta', 'Bs. ${_fmt(_ganancias['ganancia_bruta'])}', Icons.savings_outlined, AppColors.success),
        _MetricCard('Margen %', '${_ganancias['margen_porcentaje'] ?? 0}%', Icons.percent_outlined, AppColors.secondary),
      ]),
    ]);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _desde, end: _hasta));
    if (picked != null) { setState(() { _desde = picked.start; _hasta = picked.end; }); _load(); }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmt(dynamic v) { if (v == null) return '0.00'; return (double.tryParse(v.toString()) ?? 0).toStringAsFixed(2); }
}

class _MetricCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color;
  const _MetricCard(this.title, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 20), const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ])));
}
