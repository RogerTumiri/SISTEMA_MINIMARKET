import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});
  @override ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _descripCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();
  final _stockActualCtrl = TextEditingController(text: '0');
  final _stockMinCtrl = TextEditingController(text: '5');

  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _unidades = [];
  int? _catId;
  int? _unidadId;
  bool _loading = false;
  bool _isEdit = false;
  bool _aplImp = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null;
    _loadCatalogs();
    if (_isEdit) { _loadProduct(); }
  }

  Future<void> _loadCatalogs() async {
    final dio = ref.read(dioProvider);
    final res = await Future.wait([dio.get(ApiConstants.categorias), dio.get(ApiConstants.unidades)]);
    setState(() {
      _categorias = List<Map<String, dynamic>>.from(res[0].data['data'] as List);
      _unidades = List<Map<String, dynamic>>.from(res[1].data['data'] as List);
      if (_unidades.isNotEmpty && _unidadId == null) { _unidadId = (_unidades[0]['id'] as num).toInt(); }
    });
  }

  Future<void> _loadProduct() async {
    final dio = ref.read(dioProvider);
    final resp = await dio.get('${ApiConstants.productos}/${widget.productId}');
    final p = resp.data['data'] as Map<String, dynamic>;
    _nombreCtrl.text = p['nombre'] as String? ?? '';
    _barcodeCtrl.text = p['codigo_barras'] as String? ?? '';
    _descripCtrl.text = p['descripcion'] as String? ?? '';
    _precioVentaCtrl.text = p['precio_venta'].toString();
    _precioCompraCtrl.text = p['precio_compra'].toString();
    _stockActualCtrl.text = p['stock_actual'].toString();
    _stockMinCtrl.text = p['stock_minimo'].toString();
    _catId = (p['categoria']?['id'] as num?)?.toInt();
    _unidadId = (p['unidad_medida']?['id'] as num?)?.toInt();
    _aplImp = p['aplica_impuesto'] as bool? ?? false;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final body = {
        'nombre': _nombreCtrl.text.trim(),
        'codigo_barras': _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        'descripcion': _descripCtrl.text.trim().isEmpty ? null : _descripCtrl.text.trim(),
        'precio_venta': double.parse(_precioVentaCtrl.text),
        'precio_compra': double.parse(_precioCompraCtrl.text),
        'stock_actual': double.parse(_stockActualCtrl.text),
        'stock_minimo': double.parse(_stockMinCtrl.text),
        'unidad_medida_id': _unidadId,
        if (_catId != null) 'categoria_id': _catId,
        'aplica_impuesto': _aplImp,
      };
      if (_isEdit) { await dio.put('${ApiConstants.productos}/${widget.productId}', data: body); }
      else { await dio.post(ApiConstants.productos, data: body); }
      if (mounted) {
        context.go('/products');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Producto actualizado' : 'Producto creado')));
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String? ?? 'Error desconocido';
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error)); }
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar Producto' : 'Nuevo Producto'),
        leading: BackButton(onPressed: () => context.go('/products')),
        actions: [
          ElevatedButton(onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
            child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEdit ? 'Guardar' : 'Crear')),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Información General', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _barcodeCtrl, decoration: const InputDecoration(labelText: 'Código de barras', prefixIcon: Icon(Icons.barcode_reader))),
            const SizedBox(height: 12),
            TextFormField(controller: _descripCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 24),
            Text('Precios', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextFormField(controller: _precioCompraCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio Compra *', prefixText: 'Bs. '),
                validator: (v) => (v!.isEmpty || double.tryParse(v) == null) ? 'Inválido' : null)),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(controller: _precioVentaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio Venta *', prefixText: 'Bs. '),
                validator: (v) => (v!.isEmpty || double.tryParse(v) == null) ? 'Inválido' : null)),
            ]),
            const SizedBox(height: 24),
            Text('Stock', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextFormField(controller: _stockActualCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Stock Actual'))),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(controller: _stockMinCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Stock Mínimo'))),
            ]),
            const SizedBox(height: 24),
            Text('Clasificación', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_unidades.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: _unidadId,
                decoration: const InputDecoration(labelText: 'Unidad de Medida *'),
                items: _unidades.map((u) => DropdownMenuItem(value: (u['id'] as num).toInt(), child: Text('${u['nombre']} (${u['simbolo']})'))).toList(),
                onChanged: (v) => setState(() => _unidadId = v),
                validator: (v) => v == null ? 'Requerido' : null),
            const SizedBox(height: 12),
            if (_categorias.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: _catId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                isExpanded: true,
                items: [const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                  ..._categorias.map((c) => DropdownMenuItem(value: (c['id'] as num).toInt(), child: Text(c['nombre'] as String)))],
                onChanged: (v) => setState(() => _catId = v)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Aplica Impuesto'),
              value: _aplImp,
              onChanged: (v) => setState(() => _aplImp = v),
              activeThumbColor: AppColors.primary,
            ),
            const SizedBox(height: 32),
          ])))),
      ),
    );
  }
}
