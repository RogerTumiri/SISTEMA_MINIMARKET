import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final usersListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get(ApiConstants.usuarios);
  return List<Map<String, dynamic>>.from(resp.data['data'] as List);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsers = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gestión de Usuarios',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              asyncUsers.when(
                loading: () => const Text('Cargando...', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                error: (_, __) => const SizedBox.shrink(),
                data: (users) => Text('${users.length} usuarios registrados',
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
              ),
            ])),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Nuevo Usuario'),
              onPressed: () => _showCreateUserDialog(context, ref),
            ),
          ]),
        ),

        // List
        Expanded(
          child: asyncUsers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.people_outline, size: 36, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                const Text('No se pudo cargar usuarios', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                  onPressed: () => ref.invalidate(usersListProvider),
                ),
              ]),
            ),
            data: (users) => users.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.people_outline, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text('Sin usuarios registrados', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Crea el primer usuario con el botón "Nuevo Usuario"',
                      style: TextStyle(color: AppColors.textHint, fontSize: 13), textAlign: TextAlign.center),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _UserTile(user: users[i], ref: ref),
                  ),
          ),
        ),
      ]),
    );
  }

  static void _showCreateUserDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => _UserDialog(ref: ref));
  }
}

// ─── User Tile ────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final WidgetRef ref;
  const _UserTile({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final rol = user['rol'] as String? ?? 'vendedor';
    final activo = user['activo'] as bool? ?? true;
    final initials = _getInitials(user['nombre_completo'] as String? ?? user['username'] as String? ?? 'U');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow,
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _roleColor(rol).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(initials,
            style: TextStyle(color: _roleColor(rol), fontWeight: FontWeight.w700, fontSize: 15))),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user['nombre_completo'] as String? ?? user['username'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 2),
          Text(user['email'] as String? ?? '',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        ])),

        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _roleColor(rol).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_rolLabel(rol),
            style: TextStyle(color: _roleColor(rol), fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),

        // Status
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: activo ? AppColors.accentGreen : AppColors.textHint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),

        // Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textHint, size: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [
              Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8), Text('Editar'),
            ])),
            PopupMenuItem(value: 'toggle', child: Row(children: [
              Icon(activo ? Icons.block : Icons.check_circle_outline, size: 16,
                color: activo ? AppColors.error : AppColors.accentGreen),
              const SizedBox(width: 8),
              Text(activo ? 'Desactivar' : 'Activar',
                style: TextStyle(color: activo ? AppColors.error : AppColors.accentGreen)),
            ])),
          ],
          onSelected: (v) async {
            if (v == 'edit') {
              showDialog(context: context, builder: (_) => _UserDialog(ref: ref, user: user));
            }
            if (v == 'toggle') {
              try {
                await ref.read(dioProvider).patch('${ApiConstants.usuarios}/${user['id']}',
                    data: {'activo': !activo});
                ref.invalidate(usersListProvider);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
              }
            }
          },
        ),
      ]),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Color _roleColor(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin': return AppColors.primary;
      case 'cajero': return AppColors.accentOrange;
      default: return AppColors.textSecondary;
    }
  }

  String _rolLabel(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':   return 'Admin';
      case 'cajero':  return 'Cajero';
      default:        return 'Vendedor';
    }
  }
}

// ─── User Dialog ──────────────────────────────────────────────────────────────

class _UserDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Map<String, dynamic>? user;
  const _UserDialog({required this.ref, this.user});
  @override ConsumerState<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<_UserDialog> {
  final _formKey         = GlobalKey<FormState>();
  final _usernameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _nombreCtrl      = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  String _rol            = 'vendedor';
  bool   _obscure        = true;
  bool   _saving         = false;
  bool   get _isEdit     => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _usernameCtrl.text = widget.user!['username'] as String? ?? '';
      _emailCtrl.text    = widget.user!['email'] as String? ?? '';
      _nombreCtrl.text   = widget.user!['nombre_completo'] as String? ?? '';
      _rol               = widget.user!['rol'] as String? ?? 'vendedor';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'username':       _usernameCtrl.text.trim(),
        'email':          _emailCtrl.text.trim(),
        'nombre_completo': _nombreCtrl.text.trim(),
        'rol':            _rol,
        if (!_isEdit && _passwordCtrl.text.isNotEmpty) 'password': _passwordCtrl.text,
        if (_isEdit && _passwordCtrl.text.isNotEmpty) 'password':  _passwordCtrl.text,
      };
      if (_isEdit) {
        await ref.read(dioProvider).put('${ApiConstants.usuarios}/${widget.user!['id']}', data: body);
      } else {
        await ref.read(dioProvider).post(ApiConstants.usuarios, data: body);
      }
      if (mounted) {
        ref.invalidate(usersListProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Usuario actualizado' : 'Usuario creado correctamente')));
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
      title: Text(_isEdit ? 'Editar Usuario' : 'Nuevo Usuario',
        style: const TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre Completo *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(labelText: 'Usuario *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email *'),
            validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _rol,
            decoration: const InputDecoration(labelText: 'Rol *'),
            items: const [
              DropdownMenuItem(value: 'admin',    child: Text('Administrador')),
              DropdownMenuItem(value: 'cajero',   child: Text('Cajero')),
              DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
            ],
            onChanged: (v) => setState(() => _rol = v ?? 'vendedor'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: _isEdit ? 'Nueva contraseña (opcional)' : 'Contraseña *',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (!_isEdit && (v == null || v.isEmpty)) return 'Requerido';
              return null;
            },
          ),
        ])),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isEdit ? 'Guardar Cambios' : 'Crear Usuario'),
        ),
      ],
    );
  }
}
