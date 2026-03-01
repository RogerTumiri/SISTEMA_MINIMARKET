import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/models/auth_state.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});
  @override ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  List<Map<String, dynamic>> _ventas = [];
  bool _loading = true;
  int _page = 1;
  int _total = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await ref.read(dioProvider).get(ApiConstants.ventas, queryParameters: {'page': _page, 'limit': 25});
      setState(() {
        _ventas = List<Map<String, dynamic>>.from(resp.data['data'] as List);
        _total  = (resp.data['meta']['total'] as num).toInt();
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = (ref.watch(authProvider) as AuthAuthenticated?)?.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Historial de Ventas ($_total)'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Colors.white))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _ventas.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final v = _ventas[i];
                final total = (v['total'] as num).toDouble();
                final estado = v['estado'] as String;
                final isAnulada = estado == 'ANULADA';
                return ListTile(
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: (isAnulada ? AppColors.error : AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Icon(isAnulada ? Icons.cancel_outlined : Icons.receipt_long,
                      color: isAnulada ? AppColors.error : AppColors.primary),
                  ),
                  title: Text(v['numero_recibo'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${v['usuario']?['nombre_completo'] ?? '—'} · ${v['created_at']?.toString().substring(0, 16) ?? ''}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Bs. ${total.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isAnulada ? AppColors.textHint : AppColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isAnulada ? AppColors.error : AppColors.success).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                      child: Text(estado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: isAnulada ? AppColors.error : AppColors.success)),
                    ),
                  ]),
                  onTap: () => _showDetails(context, v),
                );
              },
            ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize:     0.95,
        minChildSize:     0.5,
        expand: false,
        builder: (_, ctrl) => _VentaDetail(venta: venta, onReload: _load, scrollCtrl: ctrl),
      ),
    );
  }
}

class _VentaDetail extends ConsumerWidget {
  final Map<String, dynamic> venta;
  final VoidCallback onReload;
  final ScrollController scrollCtrl;
  const _VentaDetail({required this.venta, required this.onReload, required this.scrollCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items  = venta['items']  as List? ?? [];
    final pagos  = venta['pagos']  as List? ?? [];
    final estado = venta['estado'] as String;
    return ListView(controller: scrollCtrl, padding: const EdgeInsets.all(20), children: [
      Row(children: [
        Text('Detalle Venta', style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        if (estado == 'COMPLETADA') TextButton.icon(
          icon: const Icon(Icons.cancel, color: AppColors.error),
          label: const Text('Anular', style: TextStyle(color: AppColors.error)),
          onPressed: () => _anular(context, ref),
        ),
        if (estado == 'COMPLETADA') TextButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Recibo'),
          onPressed: () {},
        ),
      ]),
      const SizedBox(height: 16),
      _row('Recibo:', venta['numero_recibo']),
      _row('Vendedor:', venta['usuario']?['nombre_completo'] ?? '—'),
      _row('Fecha:', venta['created_at']?.toString().substring(0, 19) ?? ''),
      _row('Estado:', estado),
      const Divider(),
      ...items.map((i) {
        final item = i as Map<String, dynamic>;
        return ListTile(dense: true,
          title: Text(item['nombre_producto'] as String),
          subtitle: Text('${item['cantidad']} x Bs. ${(item['precio_unitario'] as num).toStringAsFixed(2)}'),
          trailing: Text('Bs. ${(item['subtotal'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)));
      }),
      const Divider(),
      _row('Subtotal:', 'Bs. ${(venta['subtotal'] as num).toStringAsFixed(2)}'),
      _row('Impuesto:', 'Bs. ${(venta['impuesto_monto'] as num).toStringAsFixed(2)}'),
      _row('TOTAL:', 'Bs. ${(venta['total'] as num).toStringAsFixed(2)}', bold: true),
      const Divider(),
      ...pagos.map((p) {
        final pago = p as Map<String, dynamic>;
        return _row(pago['metodo_pago'] as String, 'Bs. ${(pago['monto'] as num).toStringAsFixed(2)}');
      }),
    ]);
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: bold ? 16 : null, color: bold ? AppColors.primary : null)),
    ]),
  );

  Future<void> _anular(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final motivo = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('Anular Venta'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Motivo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Anular')),
      ],
    ));
    if (motivo != null && motivo.length >= 5) {
      try {
        await ref.read(dioProvider).post('${ApiConstants.ventas}/${venta['id']}/anular', data: {'motivo': motivo});
        if (context.mounted) { Navigator.pop(context); onReload(); }
      } catch (_) {}
    }
  }
}
