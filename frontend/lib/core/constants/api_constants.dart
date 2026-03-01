class ApiConstants {
  ApiConstants._();
  
  // En producción esto vendrá de flutter_dotenv o --dart-define
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api/v1',
  );
  
  static const String iaBaseUrl = String.fromEnvironment(
    'IA_BASE_URL',
    defaultValue: 'http://localhost:8001',
  );

  // Auth
  static const String login          = '/auth/login';
  static const String logout         = '/auth/logout';
  static const String refresh        = '/auth/refresh';
  static const String me             = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword  = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // Recursos
  static const String productos     = '/productos';
  static const String categorias    = '/categorias';
  static const String proveedores   = '/proveedores';
  static const String ventas        = '/ventas';
  static const String cajas         = '/cajas';
  static const String compras       = '/compras';
  static const String inventario    = '/inventario';
  static const String reportes      = '/reportes';
  static const String usuarios      = '/usuarios';
  static const String configuracion = '/configuracion';
  static const String unidades      = '/unidades-medida';
}
