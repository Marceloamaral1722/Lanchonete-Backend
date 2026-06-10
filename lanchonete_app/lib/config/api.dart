import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:5001' : 'http://10.0.2.2:5001';

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/cadastro';
  static String get recuperarSenha => '$baseUrl/auth/recuperar-senha';
  static String get redefinirSenha => '$baseUrl/auth/redefinir-senha';
  static String get produtos => '$baseUrl/produtos';
  static String get categorias => '$baseUrl/categorias';
  static String get pedidos => '$baseUrl/pedidos';
}
