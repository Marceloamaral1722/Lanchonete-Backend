import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/produto_service.dart';
import '../../services/pedido_service.dart';
import '../../services/categoria_service.dart';
import '../../models/produto.dart';
import '../../screens/auth/login_screen.dart';
import 'meus_pedidos_screen.dart';

class CardapioScreen extends StatefulWidget {
  const CardapioScreen({super.key});

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> {
  List<Produto> _produtos = [];
  List<String> _categorias = [];
  String? _categoriaSelecionada;
  Map<int, int> _carrinho = {};
  bool _carregando = true;
  String? _token;
  Map<String, dynamic>? _sessao;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _sessao = await AuthService().getSessao();
      _token = _sessao?['token'];
      if (_token != null) {
        final res = await Future.wait([
          ProdutoService(_token!).listar(),
          CategoriaService(_token!).listar(),
        ]);
        _produtos = res[0] as List<Produto>;
        _categorias = ['Todos', ...(res[1] as List<String>)];
        _categoriaSelecionada ??= 'Todos';
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  List<Produto> get _produtosFiltrados {
    if (_categoriaSelecionada == null || _categoriaSelecionada == 'Todos') return _produtos;
    return _produtos.where((p) => p.categoria == _categoriaSelecionada).toList();
  }

  int get _totalItens => _carrinho.values.fold(0, (a, b) => a + b);
  double get _totalValor => _carrinho.entries.fold(0.0, (soma, entry) {
    final p = _produtos.where((p) => p.id == entry.key).firstOrNull;
    return soma + (p?.preco ?? 0) * entry.value;
  });

  void _addCarrinho(Produto p) => setState(() => _carrinho[p.id] = (_carrinho[p.id] ?? 0) + 1);
  void _removeCarrinho(Produto p) => setState(() {
    if ((_carrinho[p.id] ?? 0) > 0) _carrinho[p.id] = _carrinho[p.id]! - 1;
    if (_carrinho[p.id] == 0) _carrinho.remove(p.id);
  });

  Future<void> _finalizarPedido() async {
    if (_carrinho.isEmpty) return;
    final obs = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF27272A),
          title: const Text('Finalizar Pedido', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEF4444))),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Confirmar', style: TextStyle(color: Color(0xFFEF4444)))),
          ],
        );
      },
    );
    if (obs == null) return;

    try {
      final itens = _carrinho.entries.map((e) => {'produto_id': e.key, 'quantidade': e.value}).toList();
      await PedidoService(_token!).criar(itens);
      setState(() => _carrinho.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido realizado com sucesso!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _emoji(Produto p) {
    final c = p.categoria.toLowerCase();
    final n = p.nome.toLowerCase();
    if (c.contains('lanche') || c.contains('burguer')) return '🍔';
    if (c.contains('bebida') || c.contains('suco')) return '🥤';
    if (c.contains('frita') || c.contains('por')) return '🍟';
    if (c.contains('sobremesa') || c.contains('sorvete')) {
      if (n.contains('sorvete') || n.contains('split') || n.contains('gelado')) return '🍦';
      if (n.contains('browni') || n.contains('chocolate')) return '🍫';
      if (n.contains('cocada') || n.contains('coco')) return '🥥';
      if (n.contains('bolo') || n.contains('torta')) return '🎂';
      return '🍰';
    }
    if (c.contains('combo')) return '🎁';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    final nome = _sessao?['nome'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cardápio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('Olá, $nome', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
            tooltip: 'Meus Pedidos',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeusPedidosScreen(token: _token!))),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().logout();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : Column(children: [
              // Filtro categorias
              SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: _categorias.length,
                  itemBuilder: (ctx, i) {
                    final cat = _categorias[i];
                    final sel = _categoriaSelecionada == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _categoriaSelecionada = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFEF4444) : const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cat, style: TextStyle(color: sel ? Colors.white : Colors.grey, fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  },
                ),
              ),
              // Grid produtos
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _carregar,
                  color: const Color(0xFFEF4444),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final crossCount = (constraints.maxWidth / 180).floor().clamp(2, 6);
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, _totalItens > 0 ? 90 : 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _produtosFiltrados.length,
                        itemBuilder: (ctx, i) {
                          final p = _produtosFiltrados[i];
                          final qtd = _carrinho[p.id] ?? 0;
                          return _produtoCard(p, qtd);
                        },
                      );
                    },
                  ),
                ),
              ),
            ]),
      bottomNavigationBar: _totalItens > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(color: Color(0xFF27272A)),
              child: SafeArea(
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('$_totalItens', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('R\$ ${_totalValor.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                  ElevatedButton(
                    onPressed: _finalizarPedido,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Finalizar Pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
            )
          : null,
    );
  }

  Widget _produtoCard(Produto p, int qtd) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        // Imagem/emoji
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(child: Text(_emoji(p), style: const TextStyle(fontSize: 32))),
          ),
        ),
        // Info
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(p.categoria, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
              const Spacer(),
              Text('R\$ ${p.preco.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              qtd == 0
                  ? SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () => _addCarrinho(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Adicionar', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    )
                  : Row(children: [
                      _btn(Icons.remove, () => _removeCarrinho(p), const Color(0xFF3F3F46)),
                      Expanded(child: Center(child: Text('$qtd', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))),
                      _btn(Icons.add, () => _addCarrinho(p), const Color(0xFFEF4444)),
                    ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, Color cor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}
