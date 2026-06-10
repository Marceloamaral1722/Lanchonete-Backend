import 'package:flutter/material.dart';
import '../../services/pedido_service.dart';
import '../../models/pedido.dart';

class MeusPedidosScreen extends StatefulWidget {
  final String token;
  const MeusPedidosScreen({super.key, required this.token});

  @override
  State<MeusPedidosScreen> createState() => _MeusPedidosScreenState();
}

class _MeusPedidosScreenState extends State<MeusPedidosScreen> {
  List<Pedido> _pedidos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _pedidos = await PedidoService(widget.token).listar();
      _pedidos.sort((a, b) => b.id.compareTo(a.id));
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  Color _corStatus(String s) {
    switch (s) {
      case 'em_preparo': return const Color(0xFFF59E0B);
      case 'entregue': return const Color(0xFF10B981);
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _labelStatus(String s) {
    switch (s) {
      case 'em_preparo': return 'Em Preparo';
      case 'entregue': return 'Entregue';
      case 'cancelado': return 'Cancelado';
      default: return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Meus Pedidos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _carregar),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _pedidos.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 64),
                    const SizedBox(height: 12),
                    const Text('Você ainda não fez nenhum pedido.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ver Cardápio', style: TextStyle(color: Color(0xFFEF4444)))),
                  ]),
                )
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        iconColor: Colors.grey,
        collapsedIconColor: Colors.grey,
        title: Row(children: [
          Expanded(
            child: Text('Pedido #${p.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cor, width: 1),
            ),
            child: Text(_labelStatus(p.status), style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Text('R\$ ${p.total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            if (p.criadoEm != null) ...[
              const SizedBox(width: 12),
              Text(
                p.criadoEm!.length > 10 ? p.criadoEm!.substring(0, 10) : p.criadoEm!,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ]),
        ),
        children: p.itens.isEmpty
            ? [const Padding(padding: EdgeInsets.all(12), child: Text('Carregando itens...', style: TextStyle(color: Colors.grey, fontSize: 12)))]
            : p.itens.map((item) => ListTile(
                dense: true,
                leading: const Icon(Icons.fastfood, color: Color(0xFFEF4444), size: 18),
                title: Text(item.nomeProduto, style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text('${item.quantidade}x R\$ ${item.precoUnitario.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                trailing: Text('R\$ ${item.total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
              )).toList(),
      ),
    );
  }
}
