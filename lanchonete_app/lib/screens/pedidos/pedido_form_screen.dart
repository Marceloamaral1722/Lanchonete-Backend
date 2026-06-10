import 'package:flutter/material.dart';
import '../../services/pedido_service.dart';
import '../../services/produto_service.dart';
import '../../models/pedido.dart';
import '../../models/produto.dart';

class PedidoFormScreen extends StatefulWidget {
  final String token;
  final Pedido? pedido;

  const PedidoFormScreen({super.key, required this.token, this.pedido});

  @override
  State<PedidoFormScreen> createState() => _PedidoFormScreenState();
}

class _PedidoFormScreenState extends State<PedidoFormScreen> {
  List<Produto> _produtos = [];
  Map<int, int> _carrinho = {};
  String _status = 'pendente';
  bool _carregando = false;
  bool _carregandoProdutos = true;

  static const _statusOpcoes = ['pendente', 'em_preparo', 'entregue', 'cancelado'];
  static const _statusLabels = {
    'pendente': 'Pendente',
    'em_preparo': 'Em Preparo',
    'entregue': 'Entregue',
    'cancelado': 'Cancelado',
  };

  bool get _editando => widget.pedido != null;

  @override
  void initState() {
    super.initState();
    if (_editando) _status = widget.pedido!.status;
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    try {
      final lista = await ProdutoService(widget.token).listar();
      setState(() {
        _produtos = lista;
        _carregandoProdutos = false;
      });
    } catch (_) {
      setState(() => _carregandoProdutos = false);
    }
  }

  Future<void> _salvar() async {
    setState(() => _carregando = true);
    try {
      if (_editando) {
        await PedidoService(widget.token).atualizarStatus(widget.pedido!.id, _status);
      } else {
        if (_carrinho.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicione pelo menos um produto'), backgroundColor: Colors.orange),
          );
          setState(() => _carregando = false);
          return;
        }
        final itens = _carrinho.entries.map((e) => {'produto_id': e.key, 'quantidade': e.value}).toList();
        await PedidoService(widget.token).criar(itens);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _add(Produto p) => setState(() => _carrinho[p.id] = (_carrinho[p.id] ?? 0) + 1);
  void _remove(Produto p) => setState(() {
    if ((_carrinho[p.id] ?? 0) > 0) _carrinho[p.id] = _carrinho[p.id]! - 1;
    if (_carrinho[p.id] == 0) _carrinho.remove(p.id);
  });

  double get _total => _carrinho.entries.fold(0.0, (soma, e) {
    final p = _produtos.where((p) => p.id == e.key).firstOrNull;
    return soma + (p?.preco ?? 0) * e.value;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_editando ? 'Editar Status' : 'Novo Pedido',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _carregandoProdutos
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                if (_editando) ...[
                  // Apenas editar status
                  DropdownButtonFormField<String>(
                    value: _status,
                    dropdownColor: const Color(0xFF27272A),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Status', Icons.flag_outlined),
                    items: _statusOpcoes
                        .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabels[s] ?? s)))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                ] else ...[
                  // Selecionar produtos
                  const Text('Produtos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._produtos.map((p) {
                    final qtd = _carrinho[p.id] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('R\$ ${p.preco.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                        ])),
                        Row(children: [
                          _btn(Icons.remove, () => _remove(p), const Color(0xFF3F3F46)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('$qtd', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          _btn(Icons.add, () => _add(p), const Color(0xFFEF4444)),
                        ]),
                      ]),
                    );
                  }),
                  if (_carrinho.isNotEmpty) ...[
                    const Divider(color: Color(0xFF3F3F46)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                      Text('R\$ ${_total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                  ],
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_editando ? 'Salvar Status' : 'Criar Pedido',
                            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, Color cor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF27272A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}
