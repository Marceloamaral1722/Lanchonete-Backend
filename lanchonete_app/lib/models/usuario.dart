class Usuario {
  final int id;
  final String nome;
  final String email;
  final String tipo;
  final String token;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.token,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final u = json['usuario'] ?? json;
    return Usuario(
      id: u['id'],
      nome: u['nome'],
      email: u['email'],
      tipo: u['admin'] == true ? 'admin' : (u['tipo'] ?? 'comum'),
      token: json['token'] ?? json['access_token'] ?? '',
    );
  }
}
