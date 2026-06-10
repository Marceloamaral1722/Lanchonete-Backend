import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../models/produto.dart';

class ProdutoService {
  final String token;
  ProdutoService(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Produto>> listar({String? categoria}) async {
    var url = ApiConfig.produtos;
    if (categoria != null && categoria.isNotEmpty) {
      url += '?categoria=${Uri.encodeComponent(categoria)}';
    }
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Produto.fromJson(j)).toList();
    }
    throw Exception('Erro ao listar produtos');
  }

  Future<Produto> buscar(int id) async {
    final res = await http.get(Uri.parse('${ApiConfig.produtos}/$id'), headers: _headers);
    if (res.statusCode == 200) return Produto.fromJson(jsonDecode(res.body));
    throw Exception('Produto não encontrado');
  }

  Future<Produto> criar(Map<String, dynamic> dados) async {
    final res = await http.post(
      Uri.parse(ApiConfig.produtos),
      headers: _headers,
      body: jsonEncode(dados),
    );
    if (res.statusCode == 201) return Produto.fromJson(jsonDecode(res.body));
    final msg = jsonDecode(res.body)['msg'] ?? 'Erro ao criar produto';
    throw Exception(msg);
  }

  Future<Produto> atualizar(int id, Map<String, dynamic> dados) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.produtos}/$id'),
      headers: _headers,
      body: jsonEncode(dados),
    );
    if (res.statusCode == 200) return Produto.fromJson(jsonDecode(res.body));
    final msg = jsonDecode(res.body)['msg'] ?? 'Erro ao atualizar produto';
    throw Exception(msg);
  }

  Future<void> deletar(int id) async {
    final res = await http.delete(Uri.parse('${ApiConfig.produtos}/$id'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Erro ao deletar produto');
  }
}
