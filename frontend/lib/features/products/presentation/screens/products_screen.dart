import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

final productsListProvider = NotifierProvider.autoDispose<_ProductsNotifier, _ProductsState>(_ProductsNotifier.new);

class _ProductsState {
  final bool loading;
  final List<Map<String, dynamic>> items;
  final int total;
  final int page;
  final String? error;
  const _ProductsState({this.loading = true, this.items = const [], this.total = 0, this.page = 1, this.error});
}

class _ProductsNotifier extends Notifier<_ProductsState> {
  String _search = '';
  bool _stockBajo = false;

  @override
  _ProductsState build() { Future.microtask(() => load()); return const _ProductsState(); }

  @override
  _ProductsState get state => super.state;

  Future<void> load({int page = 1}) async {
    state = _ProductsState(loading: true, items: state.items, total: state.total, page: page);
    try {
      final resp = await ref.read(dioProvider).get(ApiConstants.productos, queryParameters: {
        'page': page, 'limit': 25, if (_search.isNotEmpty) 'search': _search,
        if (_stockBajo) 'stockBajo': 'true',
      });
      state = _ProductsState(loading: false,
        items: List<Map<String, dynamic>>.from(resp.data['data'] as List),
        total: (resp.data['meta']['total'] as num).toInt(), page: page);
    } catch (e) { state = _ProductsState(loading: false, error: e.toString()); }
  }

  void setSearch(String q) { _search = q; load(); }
  void toggleStockBajo() { _stockBajo = !_stockBajo; load(); }
}

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsListProvider);
    final notifier = ref.read(productsListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: TextField(controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Buscar productos...', prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), isDense: true, filled: false),
                onChanged: notifier.setSearch))),
            const SizedBox(width: 12),
            _FilterChip(label: 'Stock Bajo', selected: false, onTap: () => notifier.toggleStockBajo()),
            const SizedBox(width: 12),
            ElevatedButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Nuevo Producto'),
              onPressed: () => context.go('/products/new')),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), color: AppColors.background,
          child: const Row(children: [
            SizedBox(width: 50),
            Expanded(flex: 3, child: Text('PRODUCTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.8))),
            Expanded(flex: 2, child: Text('CATEGORÍA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.8))),
            Expanded(flex: 1, child: Text('PRECIO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.8))),
            SizedBox(width: 120, child: Text('STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.8))),
            SizedBox(width: 48),
          ])),
        Expanded(
          child: state.loading ? const Center(child: CircularProgressIndicator())
              : state.error != null ? Center(child: Text('Error: ${state.error}', style: const TextStyle(color: AppColors.error)))
              : state.items.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 36)),
                  const SizedBox(height: 16),
                  const Text('No se encontraron productos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Agrega tu primer producto con el botón "Nuevo Producto"',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13), textAlign: TextAlign.center),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: state.items.length, separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final p = state.items[i];
                    final stock = (p['stock_actual'] as num).toDouble();
                    final stockMin = (p['stock_minimo'] as num).toDouble();
                    final criticoColor = stock <= 0 ? AppColors.stockCritico : stock <= stockMin ? AppColors.stockBajo : AppColors.stockNormal;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: cardShadow),
                      child: Row(children: [
                        Container(width: 38, height: 38,
                          decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (p['codigo_barras'] != null && (p['codigo_barras'] as String).isNotEmpty)
                            Text(p['codigo_barras'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ])),
                        Expanded(flex: 2, child: Text(p['categoria']?['nombre'] as String? ?? 'Sin categoría',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Bs. ${p['precio_venta']}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                        SizedBox(width: 120, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: criticoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(stock <= 0 ? 'Sin stock' : stock <= stockMin ? 'Stock bajo' : 'Normal',
                              style: TextStyle(color: criticoColor, fontSize: 11, fontWeight: FontWeight.w700))),
                          const SizedBox(height: 2),
                          Text('$stock / Mín: $stockMin', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ])),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert, color: AppColors.textHint, size: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [
                              Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary), SizedBox(width: 8), Text('Editar')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [
                              Icon(Icons.delete_outlined, size: 16, color: AppColors.error), SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: AppColors.error))])),
                          ],
                          onSelected: (v) async {
                            if (v == 'edit') { context.go('/products/${p['id']}/edit'); }
                            if (v == 'delete') {
                              final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Confirmar eliminación'),
                                content: Text('¿Eliminar "${p['nombre']}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Eliminar')),
                                ]));
                              if (confirmed == true) {
                                try { await ref.read(dioProvider).delete('${ApiConstants.productos}/${p['id']}'); notifier.load(); } catch (_) {}
                              }
                            }
                          }),
                      ]));
                  })),
        if (state.total > 25)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${state.total} productos en total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ])),
      ]),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  late bool _selected;
  @override void initState() { super.initState(); _selected = widget.selected; }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { setState(() => _selected = !_selected); widget.onTap(); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: _selected ? AppColors.primary50 : AppColors.surface,
          borderRadius: BorderRadius.circular(12), border: Border.all(color: _selected ? AppColors.primary : AppColors.border)),
        child: Row(children: [
          Icon(Icons.filter_list, size: 16, color: _selected ? AppColors.primary : AppColors.textHint),
          const SizedBox(width: 6),
          Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: _selected ? AppColors.primary : AppColors.textSecondary)),
        ])));
  }
}
