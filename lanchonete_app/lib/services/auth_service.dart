import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../models/usuario.dart';

class AuthService {
  static const _tokenKey = 'token';
  static const _nomeKey = 'nome';
  static const _emailKey = 'email';
  static const _tipoKey = 'tipo';
  static const _idKey = 'id';

  Future<Usuario> login(String email, String senha) async {
    final res = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final usuario = Usuario.fromJson(data);
      await _salvarSessao(usuario);
      return usuario;
    }
    final msg = jsonDecode(res.body)['msg'] ?? 'Erro ao fazer login';
    throw Exception(msg);
  }

  Future<Usuario> cadastrar(String nome, String email, String senha) async {
    final res = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
    );
    if (res.statusCode == 201) {
      return login(email, senha);
    }
    final msg = jsonDecode(res.body)['msg'] ?? 'Erro ao cadastrar';
    throw Exception(msg);
  }

  Future<void> _salvarSessao(Usuario u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, u.token);
    await prefs.setString(_nomeKey, u.nome);
    await prefs.setString(_emailKey, u.email);
    await prefs.setString(_tipoKey, u.tipo);
    await prefs.setInt(_idKey, u.id);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;
    return {
      'token': token,
      'nome': prefs.getString(_nomeKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
      'tipo': prefs.getString(_tipoKey) ?? 'comum',
      'id': prefs.getInt(_idKey) ?? 0,
    };
  }

  Future<String> recuperarSenha(String email) async {
    final res = await http.post(
      Uri.parse(ApiConfig.recuperarSenha),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['token'] ?? '';
    }
    throw Exception(data['message'] ?? 'Erro ao solicitar recuperação');
  }

  Future<void> redefinirSenha(String token, String novaSenha) async {
    final res = await http.post(
      Uri.parse(ApiConfig.redefinirSenha),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'nova_senha': novaSenha}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao redefinir senha');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
