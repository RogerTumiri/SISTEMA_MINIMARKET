import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final inventoryAjustesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('${ApiConstants.inventario}/ajustes');
  return List<Map<String, dynamic>>.from(resp.data['data'] as List);
});

final inventoryComprasProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get(ApiConstants.compras);
  return List<Map<String, dynamic>>.from(resp.data['data'] as List);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(length: 2, child: Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Inventario',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            const Text('Gestión de ajustes y compras',
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
            const SizedBox(height: 12),
            const TabBar(
              tabs: [
                Tab(text: 'Ajustes de Stock'),
                Tab(text: 'Registro de Compras'),
              ],
            ),
          ]),
        ),

        Expanded(
          child: TabBarView(children: [
            _AjustesTab(),
            _ComprasTab(),
          ]),
        ),
      ]),
      floatingActionButton: Builder(builder: (context) {
        final tabIndex = DefaultTabController.of(context).index;
        return FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text(tabIndex == 0 ? 'Nuevo Ajuste' : 'Nueva Compra'),
          onPressed: () {
            if (tabIndex == 0) {
              _showAjusteDialog(context, ref);
            } else {
              _showCompraDialog(context, ref);
            }
          },
        );
      }),
    ));
  }

  static void _showAjusteDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => _AjusteDialog(ref: ref));
  }

  static void _showCompraDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => _CompraDialog(ref: ref));
  }
}

// ─── Ajustes Tab ──────────────────────────────────────────────────────────────

class _AjustesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(inventoryAjustesProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _EmptyState(
        icon: Icons.tune,
        title: 'Ajustes de Inventario',
        subtitle: 'Registra mermas, ajustes de stock y movimientos manuales.',
        error: e.toString(),
      ),
      data: (ajustes) => ajustes.isEmpty
          ? const _EmptyState(
              icon: Icons.tune,
              title: 'Sin ajustes registrados',
              subtitle: 'Presiona "Nuevo Ajuste" para registrar movimientos de stock.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ajustes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = ajustes[i];
                final tipo = a['tipo'] as String? ?? '';
                final isPositivo = tipo == 'ENTRADA';
                final tipoColor = isPositivo ? AppColors.accentGreen : AppColors.error;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: cardShadow,
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: tipoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPositivo ? Icons.add_circle_outline : Icons.remove_circle_outline,
                        color: tipoColor, size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a['producto']?['nombre'] as String? ?? 'Producto',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(a['motivo'] as String? ?? tipo,
                        style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${isPositivo ? '+' : ''}${a['cantidad']}',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: tipoColor)),
                      Text(_formatDate(a['created_at'] as String? ?? ''),
                        style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                    ]),
                  ]),
                );
              },
            ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }
}

// ─── Compras Tab ──────────────────────────────────────────────────────────────

class _ComprasTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(inventoryComprasProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Registro de Compras',
        subtitle: 'Registra entradas de mercadería desde proveedores.',
        error: e.toString(),
      ),
      data: (compras) => compras.isEmpty
          ? const _EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Sin compras registradas',
              subtitle: 'Presiona "Nueva Compra" para registrar entradas de mercadería.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: compras.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = compras[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: cardShadow,
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['proveedor']?['nombre_empresa'] as String? ?? 'Proveedor',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${c['total_items'] ?? 0} ítems · Bs. ${c['total'] ?? '0.00'}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(c['estado'] as String? ?? 'RECIBIDA',
                        style: const TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? error;
  const _EmptyState({required this.icon, required this.title, required this.subtitle, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.textHint, fontSize: 13), textAlign: TextAlign.center),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text('(${error!})', style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
        ]),
      ),
    );
  }
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────

class _AjusteDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AjusteDialog({required this.ref});
  @override ConsumerState<_AjusteDialog> createState() => _AjusteDialogState();
}

class _AjusteDialogState extends ConsumerState<_AjusteDialog> {
  final _formKey       = GlobalKey<FormState>();
  final _cantidadCtrl  = TextEditingController();
  final _motivoCtrl    = TextEditingController();
  String _tipo         = 'SALIDA';
  List<Map<String,dynamic>> _productos = [];
  String? _productoId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    try {
      final resp = await ref.read(dioProvider).get(ApiConstants.productos, queryParameters: {'limit': 200});
      setState(() => _productos = List<Map<String,dynamic>>.from(resp.data['data'] as List));
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('${ApiConstants.inventario}/ajustes', data: {
        'producto_id': _productoId,
        'tipo':        _tipo,
        'cantidad':    double.parse(_cantidadCtrl.text),
        'motivo':      _motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim(),
      });
      if (mounted) {
        ref.invalidate(inventoryAjustesProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajuste registrado correctamente')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Nuevo Ajuste de Stock', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_productos.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Producto *'),
              items: _productos.map((p) => DropdownMenuItem(
                value: p['id'] as String, child: Text(p['nombre'] as String),
              )).toList(),
              onChanged: (v) => setState(() => _productoId = v),
              validator: (v) => v == null ? 'Seleccione un producto' : null,
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo *'),
            items: const [
              DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada (añadir stock)')),
              DropdownMenuItem(value: 'SALIDA',  child: Text('Salida (merma / retiro)')),
              DropdownMenuItem(value: 'AJUSTE',  child: Text('Ajuste manual')),
            ],
            onChanged: (v) => setState(() => _tipo = v ?? 'SALIDA'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cantidadCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cantidad *'),
            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Ingrese una cantidad válida' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motivoCtrl,
            decoration: const InputDecoration(labelText: 'Motivo / Descripción'),
            maxLines: 2,
          ),
        ])),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar'),
        ),
      ],
    );
  }
}

class _CompraDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CompraDialog({required this.ref});
  @override ConsumerState<_CompraDialog> createState() => _CompraDialogState();
}

class _CompraDialogState extends ConsumerState<_CompraDialog> {
  final _formKey       = GlobalKey<FormState>();
  final _cantidadCtrl  = TextEditingController();
  final _costoCtrl     = TextEditingController();
  List<Map<String,dynamic>> _productos   = [];
  List<Map<String,dynamic>> _proveedores = [];
  String? _productoId;
  String? _proveedorId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      final results = await Future.wait([
        ref.read(dioProvider).get(ApiConstants.productos,   queryParameters: {'limit': 200}),
        ref.read(dioProvider).get(ApiConstants.proveedores, queryParameters: {'limit': 100}),
      ]);
      setState(() {
        _productos   = List<Map<String,dynamic>>.from(results[0].data['data'] as List);
        _proveedores = List<Map<String,dynamic>>.from(results[1].data['data'] as List);
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post(ApiConstants.compras, data: {
        'proveedor_id': _proveedorId,
        'items': [
          {
            'producto_id': _productoId,
            'cantidad':    double.parse(_cantidadCtrl.text),
            'precio_unitario': double.parse(_costoCtrl.text),
          }
        ],
      });
      if (mounted) {
        ref.invalidate(inventoryComprasProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra registrada correctamente')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Registrar Compra', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_proveedores.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Proveedor'),
              items: _proveedores.map((p) => DropdownMenuItem(
                value: p['id'] as String, child: Text(p['nombre_empresa'] as String? ?? ''),
              )).toList(),
              onChanged: (v) => setState(() => _proveedorId = v),
            ),
          const SizedBox(height: 12),
          if (_productos.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Producto *'),
              items: _productos.map((p) => DropdownMenuItem(
                value: p['id'] as String, child: Text(p['nombre'] as String),
              )).toList(),
              onChanged: (v) => setState(() => _productoId = v),
              validator: (v) => v == null ? 'Seleccione un producto' : null,
            ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _cantidadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cantidad *'),
              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _costoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Costo unit. *', prefixText: 'Bs. '),
              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
            )),
          ]),
        ])),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar Compra'),
        ),
      ],
    );
  }
}
