import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../models/pedido.dart';

class PedidoService {
  final String token;
  PedidoService(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Pedido>> listar() async {
    final res = await http.get(Uri.parse(ApiConfig.pedidos), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Pedido.fromJson(j)).toList();
    }
    throw Exception('Erro ao listar pedidos');
  }

  Future<Pedido> criar(List<Map<String, dynamic>> itens) async {
    final res = await http.post(
      Uri.parse(ApiConfig.pedidos),
      headers: _headers,
      body: jsonEncode({'itens': itens}),
    );
    if (res.statusCode == 201) return Pedido.fromJson(jsonDecode(res.body));
    final msg = jsonDecode(res.body)['message'] ?? 'Erro ao criar pedido';
    throw Exception(msg);
  }

  Future<Pedido> atualizarStatus(int id, String status) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.pedidos}/$id'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode == 200) return Pedido.fromJson(jsonDecode(res.body));
    final msg = jsonDecode(res.body)['message'] ?? 'Erro ao atualizar';
    throw Exception(msg);
  }

  Future<void> deletar(int id) async {
    final res = await http.delete(Uri.parse('${ApiConfig.pedidos}/$id'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Erro ao deletar pedido');
  }
}
