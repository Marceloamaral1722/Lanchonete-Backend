import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class CategoriaService {
  final String token;
  CategoriaService(this.token);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
  };

  Future<List<String>> listar() async {
    final res = await http.get(Uri.parse(ApiConfig.categorias), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<String>();
    }
    throw Exception('Erro ao listar categorias');
  }
}
