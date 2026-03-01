import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Configuración')),
      body: ListView(children: [
        const SizedBox(height: 20),
        _Section('Negocio', [
          _SettingTile(Icons.store_outlined, 'Nombre del Negocio', 'Mi MiniMarket'),
          _SettingTile(Icons.location_on_outlined, 'Dirección', 'Av. Siempre Viva'),
          _SettingTile(Icons.phone_outlined, 'Teléfono', '+591 777-0000'),
          _SettingTile(Icons.receipt_long_outlined, 'NIT/RUC', '1234567890'),
        ]),
        _Section('Sistema', [
          _SettingTile(Icons.percent_outlined, 'Porcentaje IVA', '13%'),
          _SettingTile(Icons.currency_exchange_outlined, 'Moneda', 'BOB (Bs.)'),
          _SettingTile(Icons.language_outlined, 'Idioma', 'Español'),
        ]),
        _Section('Seguridad', [
          _SettingTile(Icons.security_outlined, 'Política de contraseñas', 'Mín. 8 caracteres'),
          _SettingTile(Icons.timer_outlined, 'Cierre sesión automático', '8 horas'),
        ]),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
          color: AppColors.primary, letterSpacing: 0.5)),
    ),
    Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Column(children: children)),
    const SizedBox(height: 8),
  ]);
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SettingTile(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary, size: 20),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    onTap: () {},
  );
}
