import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

// ─── Cart State ───────────────────────────────────────────
class CartItem {
  final String productoId;
  final String nombre;
  final String? codigoBarras;
  final double precioUnitario;
  final double precioCosto;
  double cantidad;
  double descuentoItem;
  final bool aplicaImpuesto;
  final double porcentajeImpuesto;

  CartItem({
    required this.productoId,
    required this.nombre,
    this.codigoBarras,
    required this.precioUnitario,
    required this.precioCosto,
    this.cantidad = 1,
    this.descuentoItem = 0,
    this.aplicaImpuesto = false,
    this.porcentajeImpuesto = 0,
  });

  double get subtotal => (precioUnitario - descuentoItem) * cantidad;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addOrUpdate(CartItem newItem) {
    final idx = state.indexWhere((i) => i.productoId == newItem.productoId);
    if (idx >= 0) {
      state = [
        ...state.sublist(0, idx),
        CartItem(
          productoId:         state[idx].productoId,
          nombre:             state[idx].nombre,
          codigoBarras:       state[idx].codigoBarras,
          precioUnitario:     state[idx].precioUnitario,
          precioCosto:        state[idx].precioCosto,
          cantidad:           state[idx].cantidad + 1,
          aplicaImpuesto:     state[idx].aplicaImpuesto,
          porcentajeImpuesto: state[idx].porcentajeImpuesto,
        ),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, newItem];
    }
  }

  void updateQty(String productoId, double qty) {
    if (qty <= 0) { remove(productoId); return; }
    state = state.map((i) => i.productoId == productoId
        ? CartItem(
            productoId: i.productoId, nombre: i.nombre, codigoBarras: i.codigoBarras,
            precioUnitario: i.precioUnitario, precioCosto: i.precioCosto, cantidad: qty,
            aplicaImpuesto: i.aplicaImpuesto, porcentajeImpuesto: i.porcentajeImpuesto,
          )
        : i
    ).toList();
  }

  void remove(String productoId) {
    state = state.where((i) => i.productoId != productoId).toList();
  }

  void clear() => state = [];

  double get subtotal => state.fold(0, (s, i) => s + i.subtotal);
  double get impuesto => state.fold(0, (s, i) => i.aplicaImpuesto
      ? s + i.subtotal * (i.porcentajeImpuesto / 100) : s);
  double get total => subtotal + impuesto;
}

final cartProvider = NotifierProvider.autoDispose<CartNotifier, List<CartItem>>(
    CartNotifier.new);

// ─── POS Screen ───────────────────────────────────────────
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _barcodeCtrl= TextEditingController();
  final _pagosCtrl  = TextEditingController(text: '0.00');

  String _metodoPago = 'EFECTIVO';
  bool   _processing = false;

  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _barcodeCtrl.dispose();
    _pagosCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String q) async {
    if (q.length < 2) { setState(() => _searchResults = []); return; }
    try {
      final dio  = ref.read(dioProvider);
      final resp = await dio.get(ApiConstants.productos,
          queryParameters: {'search': q, 'limit': '10', 'activo': 'true'});
      setState(() => _searchResults = List<Map<String, dynamic>>.from(resp.data['data'] as List));
    } catch (_) {}
  }

  Future<void> _searchBarcode(String code) async {
    if (code.isEmpty) return;
    try {
      final dio  = ref.read(dioProvider);
      final resp = await dio.get('${ApiConstants.productos}/barcode/$code');
      _addToCart(resp.data['data'] as Map<String, dynamic>);
      _barcodeCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código no encontrado'), backgroundColor: AppColors.error));
      }
    }
  }

  void _addToCart(Map<String, dynamic> prod) {
    ref.read(cartProvider.notifier).addOrUpdate(CartItem(
      productoId:         prod['id'] as String,
      nombre:             prod['nombre'] as String,
      codigoBarras:       prod['codigo_barras'] as String?,
      precioUnitario:     double.tryParse(prod['precio_venta'].toString()) ?? 0,
      precioCosto:        double.tryParse(prod['precio_costo']?.toString() ?? '0') ?? 0,
      aplicaImpuesto:     prod['aplica_impuesto'] as bool? ?? false,
      porcentajeImpuesto: double.tryParse(prod['porcentaje_impuesto']?.toString() ?? '0') ?? 0,
    ));
    setState(() => _searchResults = []);
    _searchCtrl.clear();
  }

  Future<void> _processSale() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final cartNotifier = ref.read(cartProvider.notifier);
    final montoIngresado = double.tryParse(_pagosCtrl.text) ?? 0;
    final total = cartNotifier.total;

    if (_metodoPago == 'EFECTIVO' && montoIngresado < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Monto insuficiente. Total: Bs. ${total.toStringAsFixed(2)}'),
            backgroundColor: AppColors.error));
      return;
    }

    setState(() => _processing = true);
    try {
      final dio  = ref.read(dioProvider);
      final resp = await dio.post(ApiConstants.ventas, data: {
        'items': cart.map((i) => {
          'producto_id': i.productoId,
          'cantidad':    i.cantidad,
          'descuento_item': i.descuentoItem,
        }).toList(),
        'pagos': [{
          'metodo_pago': _metodoPago,
          'monto': _metodoPago == 'EFECTIVO' ? montoIngresado : total,
        }],
      });
      final data = resp.data['data'] as Map<String, dynamic>;
      final vuelto = (data['vuelto'] as num?)?.toDouble() ?? 0;
      cartNotifier.clear();
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.check_circle_outline, color: AppColors.success),
              SizedBox(width: 8), Text('Venta Registrada'),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recibo: ${data['numero_recibo']}'),
              Text('Total: Bs. ${(data['total'] as num).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              if (vuelto > 0)
                Text('Vuelto: Bs. ${vuelto.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
              ElevatedButton.icon(
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Imprimir Recibo'),
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implementar impresión
                },
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String? ?? 'Error al procesar venta';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart        = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;

    Widget posPanel = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Text('Punto de Venta', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),

        // Barcode scanner input
        TextField(
          controller: _barcodeCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Escanear código de barras',
            prefixIcon: Icon(Icons.barcode_reader),
            hintText: 'Escanea o escribe el código',
          ),
          onSubmitted: _searchBarcode,
        ),
        const SizedBox(height: 12),

        // Búsqueda por nombre
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            labelText: 'Buscar producto por nombre',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _searchProducts,
        ),

        // Resultados de búsqueda
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color:  Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: ListView(
              shrinkWrap: true,
              children: _searchResults.map((p) => ListTile(
                title: Text(p['nombre'] as String),
                subtitle: Text('Bs. ${p['precio_venta']} · Stock: ${p['stock_actual']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () => _addToCart(p),
                ),
                onTap: () => _addToCart(p),
              )).toList(),
            ),
          ),
      ]),
    );

    Widget cartPanel = Container(
      color: Colors.white,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            if (cart.isNotEmpty)
              TextButton.icon(
                onPressed: () { ref.read(cartProvider.notifier).clear(); },
                icon: const Icon(Icons.clear_all, color: Colors.white70, size: 16),
                label: const Text('Limpiar', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ]),
        ),

        // Cart items
        Expanded(
          child: cart.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text('Carrito vacío', style: TextStyle(color: AppColors.textHint)),
                ]))
              : ListView.separated(
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    return ListTile(
                      title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      subtitle: Text('Bs. ${item.precioUnitario.toStringAsFixed(2)} c/u'),
                      leading: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                        onPressed: () => cartNotifier.updateQty(item.productoId, item.cantidad - 1),
                      ),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${item.cantidad.toStringAsFixed(item.cantidad == item.cantidad.roundToDouble() ? 0 : 2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                          onPressed: () => cartNotifier.updateQty(item.productoId, item.cantidad + 1),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text('Bs.${item.subtotal.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ]),
                    );
                  },
                ),
        ),

        // Summary & Checkout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Subtotal:'), Text('Bs. ${cartNotifier.subtotal.toStringAsFixed(2)}'),
            ]),
            if (cartNotifier.impuesto > 0)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Impuesto:'), Text('Bs. ${cartNotifier.impuesto.toStringAsFixed(2)}'),
              ]),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Bs. ${cartNotifier.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            // Método de pago
            DropdownButtonFormField<String>(
              value: _metodoPago,
              decoration: const InputDecoration(labelText: 'Método de pago'),
              items: const [
                DropdownMenuItem(value: 'EFECTIVO',        child: Text('Efectivo')),
                DropdownMenuItem(value: 'TARJETA_DEBITO',  child: Text('Tarjeta Débito')),
                DropdownMenuItem(value: 'TARJETA_CREDITO', child: Text('Tarjeta Crédito')),
                DropdownMenuItem(value: 'QR',              child: Text('QR')),
              ],
              onChanged: (v) => setState(() => _metodoPago = v!),
            ),
            if (_metodoPago == 'EFECTIVO') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _pagosCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto entregado',
                  prefixText: 'Bs. ',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (double.tryParse(_pagosCtrl.text) != null &&
                  double.parse(_pagosCtrl.text) >= cartNotifier.total)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Vuelto:', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    Text(
                      'Bs. ${(double.parse(_pagosCtrl.text) - cartNotifier.total).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: cart.isEmpty || _processing ? null : _processSale,
                icon: _processing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.payment),
                label: Text(_processing ? 'Procesando...' : 'Cobrar Bs. ${cartNotifier.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ]),
    );

    if (isWide) {
      return Row(children: [
        Expanded(flex: 3, child: posPanel),
        Container(width: 1, color: AppColors.border),
        SizedBox(width: 360, child: cartPanel),
      ]);
    }

    return Column(children: [
      Expanded(child: posPanel),
      SizedBox(height: 420, child: cartPanel),
    ]);
  }
}
