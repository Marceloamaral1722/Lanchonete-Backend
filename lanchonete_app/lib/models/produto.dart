class Produto {
  final int id;
  final String nome;
  final double preco;
  final String categoria;
  final String? descricao;
  final String? imagemUrl;
  final bool ativo;
  final int estoque;

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.categoria,
    this.descricao,
    this.imagemUrl,
    required this.ativo,
    required this.estoque,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      nome: json['nome'],
      preco: (json['preco'] as num).toDouble(),
      categoria: json['categoria'] ?? '',
      descricao: json['descricao'],
      imagemUrl: json['imagem_url'],
      ativo: json['ativo'] ?? true,
      estoque: json['estoque'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'preco': preco,
    'categoria': categoria,
    'descricao': descricao ?? '',
    'imagem_url': imagemUrl ?? '',
    'ativo': ativo,
    'estoque': estoque,
  };
}
