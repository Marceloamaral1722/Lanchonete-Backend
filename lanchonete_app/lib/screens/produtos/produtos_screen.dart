import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/produto_service.dart';
import '../../models/produto.dart';
import 'produto_form_screen.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  List<Produto> _produtos = [];
  bool _carregando = true;
  String? _token;
  String? _tipo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final sessao = await AuthService().getSessao();
      _token = sessao?['token'];
      _tipo = sessao?['tipo'];
      if (_token != null) {
        _produtos = await ProdutoService(_token!).listar();
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _deletar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        content: const Text('Deseja remover este produto?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ProdutoService(_token!).deletar(id);
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _emoji(String categoria) {
    final c = categoria.toLowerCase();
    if (c.contains('lanche') || c.contains('burguer')) return '🍔';
    if (c.contains('bebida') || c.contains('suco')) return '🥤';
    if (c.contains('frita') || c.contains('por')) return '🍟';
    if (c.contains('sobremesa') || c.contains('sorvete')) return '🍰';
    if (c.contains('combo')) return '🎁';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _tipo == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Produtos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _carregar),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFEF4444),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProdutoFormScreen(token: _token!)),
              ).then((_) => _carregar()),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _produtos.isEmpty
              ? const Center(child: Text('Nenhum produto cadastrado.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: const Color(0xFFEF4444),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _produtos.length,
                    itemBuilder: (ctx, i) {
                      final p = _produtos[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(_emoji(p.categoria), style: const TextStyle(fontSize: 22))),
                          ),
                          title: Text(p.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${p.categoria} • Estoque: ${p.estoque}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'R\$ ${p.preco.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: p.ativo ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.ativo ? 'Ativo' : 'Inativo',
                                      style: TextStyle(color: p.ativo ? const Color(0xFF10B981) : Colors.grey, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => ProdutoFormScreen(token: _token!, produto: p)),
                                      ).then((_) => _carregar()),
                                      child: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _deletar(p.id),
                                      child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
