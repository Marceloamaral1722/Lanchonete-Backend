class ItemPedido {
  final int id;
  final int produtoId;
  final String nomeProduto;
  final int quantidade;
  final double precoUnitario;

  ItemPedido({
    required this.id,
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidade,
    required this.precoUnitario,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    return ItemPedido(
      id: json['id'],
      produtoId: json['produto_id'],
      nomeProduto: json['nome_produto'] ?? '',
      quantidade: json['quantidade'],
      precoUnitario: (json['preco_unitario'] as num).toDouble(),
    );
  }

  double get total => precoUnitario * quantidade;
}

class Pedido {
  final int id;
  final int usuarioId;
  final String nomeUsuario;
  final String status;
  final double total;
  final String? criadoEm;
  final List<ItemPedido> itens;

  Pedido({
    required this.id,
    required this.usuarioId,
    required this.nomeUsuario,
    required this.status,
    required this.total,
    this.criadoEm,
    this.itens = const [],
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final itensJson = json['itens'] as List? ?? [];
    return Pedido(
      id: json['id'],
      usuarioId: json['usuario_id'] ?? 0,
      nomeUsuario: json['nome_usuario'] ?? '',
      status: json['status'] ?? 'pendente',
      total: (json['total'] as num).toDouble(),
      criadoEm: json['criado_em'],
      itens: itensJson.map((i) => ItemPedido.fromJson(i)).toList(),
    );
  }
}
