import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});
  @override ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  List<Map<String, dynamic>> _predicciones = [];
  List<Map<String, dynamic>> _sugerencias = [];
  bool _loading = false;
  bool _executing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final r = await Future.wait([
        dio.get('http://localhost:8001/predicciones/'),
        dio.get('http://localhost:8001/sugerencias/'),
      ]);
      setState(() {
        _predicciones = List<Map<String, dynamic>>.from(r[0].data['data'] as List? ?? []);
        _sugerencias = List<Map<String, dynamic>>.from(r[1].data['data'] as List? ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _ejecutar() async {
    setState(() => _executing = true);
    try {
      await ref.read(dioProvider).post('http://localhost:8001/predicciones/ejecutar');
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Predicciones ejecutándose... espere unos minutos.'))); }
    } finally { setState(() => _executing = false); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false, title: const Text('IA — Predicciones'),
        bottom: const TabBar(indicatorColor: AppColors.primary, labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: [Tab(text: 'Predicciones'), Tab(text: 'Sugerencias')]),
        actions: [
          ElevatedButton.icon(
            icon: _executing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Re-entrenar'), onPressed: _executing ? null : _ejecutar),
          const SizedBox(width: 8),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AppColors.textSecondary)),
        ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : TabBarView(children: [
              _predicciones.isEmpty
                  ? _emptyState('No hay predicciones', 'Ejecuta el modelo para generar predicciones.')
                  : ListView.separated(padding: const EdgeInsets.all(12), itemCount: _predicciones.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = _predicciones[i];
                        final conf = (p['confianza'] as num?)?.toDouble() ?? 0;
                        final preds = p['predicciones'] as Map<String, dynamic>? ?? {};
                        return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(p['nombre_producto'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _confColor(conf).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text('${conf.toStringAsFixed(0)}% confianza', style: TextStyle(fontSize: 11, color: _confColor(conf), fontWeight: FontWeight.bold))),
                          ]),
                          const SizedBox(height: 4),
                          Text('Algoritmo: ${p['algoritmo']}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                          const SizedBox(height: 12),
                          Row(children: [
                            _predPill('7 días', preds['7_dias']), const SizedBox(width: 8),
                            _predPill('14 días', preds['14_dias']), const SizedBox(width: 8),
                            _predPill('30 días', preds['30_dias']),
                          ]),
                        ])));
                      }),
              _sugerencias.isEmpty
                  ? _emptyState('No hay sugerencias', 'Las sugerencias de recompra se generan automáticamente.')
                  : ListView.separated(padding: const EdgeInsets.all(12), itemCount: _sugerencias.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = _sugerencias[i];
                        return Card(child: ListTile(
                          leading: const Icon(Icons.shopping_cart_checkout, color: AppColors.primary),
                          title: Text(s['producto_nombre'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('Proveedor: ${s['proveedor_nombre'] ?? 'Sin proveedor'}\nPedir: ${(s['cantidad_sugerida'] as num).toStringAsFixed(0)} unidades'),
                          isThreeLine: true,
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                              onPressed: () => _aprobar(s['id'] as String, (s['cantidad_sugerida'] as num).toDouble())),
                            IconButton(icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                              onPressed: () => _rechazar(s['id'] as String)),
                          ])));
                      }),
            ]),
    ));
  }

  Widget _emptyState(String title, String sub) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.auto_awesome_outlined, size: 64, color: AppColors.textHint),
    const SizedBox(height: 12),
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    Text(sub, style: const TextStyle(color: AppColors.textHint), textAlign: TextAlign.center),
  ]));

  Widget _predPill(String label, dynamic value) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      Text(value != null ? '${(value as num).toStringAsFixed(1)} u.' : '—',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
    ])));

  Color _confColor(double c) => c >= 70 ? AppColors.success : c >= 40 ? AppColors.warning : AppColors.error;

  Future<void> _aprobar(String id, double cantidad) async {
    await ref.read(dioProvider).patch('http://localhost:8001/sugerencias/$id/aprobar', data: {'cantidad_aprobada': cantidad});
    _load();
  }

  Future<void> _rechazar(String id) async {
    await ref.read(dioProvider).patch('http://localhost:8001/sugerencias/$id/rechazar', data: {});
    _load();
  }
}
