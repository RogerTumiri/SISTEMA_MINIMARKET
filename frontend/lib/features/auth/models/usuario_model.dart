class UsuarioModel {
  final String id;
  final String nombreCompleto;
  final String username;
  final String email;
  final String rol;
  final DateTime? ultimoLogin;

  const UsuarioModel({
    required this.id,
    required this.nombreCompleto,
    required this.username,
    required this.email,
    required this.rol,
    this.ultimoLogin,
  });

  bool get isAdmin => rol == 'ADMINISTRADOR';

  factory UsuarioModel.fromJson(Map<String, dynamic> json) => UsuarioModel(
    id:              json['id']               as String,
    nombreCompleto:  json['nombre_completo']  as String,
    username:        json['username']         as String,
    email:           json['email']            as String,
    rol:             json['rol']              as String,
    ultimoLogin:     json['ultimo_login'] != null
        ? DateTime.tryParse(json['ultimo_login'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre_completo': nombreCompleto,
    'username': username, 'email': email, 'rol': rol,
  };

  @override
  String toString() => 'UsuarioModel(username: $username, rol: $rol)';
}
