import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/pedido_service.dart';
import '../../models/pedido.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  List<Pedido> _pedidos = [];
  bool _carregando = true;
  String? _token;
  bool _isAdmin = false;

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
      _isAdmin = sessao?['tipo'] == 'admin';
      if (_token != null) {
        _pedidos = await PedidoService(_token!).listar();
        _pedidos.sort((a, b) => b.id.compareTo(a.id));
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _mudarStatus(Pedido p, String novoStatus) async {
    try {
      await PedidoService(_token!).atualizarStatus(p.id, novoStatus);
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        content: const Text('Deseja remover este pedido?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await PedidoService(_token!).deletar(id);
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _corStatus(String s) {
    switch (s) {
      case 'pendente': return const Color(0xFFF59E0B);
      case 'em_preparo': return const Color(0xFF3B82F6);
      case 'entregue': return const Color(0xFF10B981);
      case 'cancelado': return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }

  String _labelStatus(String s) {
    const map = {'pendente': 'Pendente', 'em_preparo': 'Em Preparo', 'entregue': 'Entregue', 'cancelado': 'Cancelado'};
    return map[s] ?? s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Pedidos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _carregar),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _pedidos.isEmpty
              ? const Center(child: Text('Nenhum pedido encontrado.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: const Color(0xFFEF4444),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pedidos.length,
                    itemBuilder: (ctx, i) => _pedidoCard(_pedidos[i]),
                  ),
                ),
    );
  }

  Widget _pedidoCard(Pedido p) {
    final cor = _corStatus(p.status);
    final inicial = p.nomeUsuario.isNotEmpty ? p.nomeUsuario[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        iconColor: Colors.grey,
        collapsedIconColor: Colors.grey,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEF4444),
          child: Text(inicial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        title: Row(children: [
          Expanded(child: Text('Pedido #${p.id} — ${p.nomeUsuario}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: cor)),
            child: Text(_labelStatus(p.status), style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text('R\$ ${p.total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        children: [
          if (p.itens.isNotEmpty)
            ...p.itens.map((item) => ListTile(
              dense: true,
              leading: const Icon(Icons.fastfood, color: Color(0xFFEF4444), size: 16),
              title: Text(item.nomeProduto, style: const TextStyle(color: Colors.white, fontSize: 12)),
              trailing: Text('${item.quantidade}x • R\$ ${item.total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(children: [
              if (_isAdmin && p.status == 'pendente')
                _actionBtn('Preparar', const Color(0xFF3B82F6), () => _mudarStatus(p, 'em_preparo')),
              if (_isAdmin && p.status == 'em_preparo') ...[
                _actionBtn('Entregar', const Color(0xFF10B981), () => _mudarStatus(p, 'entregue')),
              ],
              const Spacer(),
              if (_isAdmin && p.status != 'entregue' && p.status != 'cancelado')
                _actionBtn('Cancelar', Colors.red, () => _mudarStatus(p, 'cancelado')),
              if (_isAdmin) ...[
                const SizedBox(width: 6),
                _actionBtn('Excluir', const Color(0xFF52525B), () => _deletar(p.id)),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color cor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
