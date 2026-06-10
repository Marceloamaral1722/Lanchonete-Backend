import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/produto_service.dart';
import '../../services/pedido_service.dart';
import '../../models/produto.dart';
import '../../models/pedido.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/produtos/produtos_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _sessao;
  List<Produto> _produtos = [];
  List<Pedido> _pedidos = [];
  bool _carregando = true;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _sessao = await AuthService().getSessao();
      _token = _sessao?['token'] as String? ?? '';
      final res = await Future.wait([
        ProdutoService(_token).listar(),
        PedidoService(_token).listar(),
      ]);
      _produtos = res[0] as List<Produto>;
      _pedidos = res[1] as List<Pedido>;
      _pedidos.sort((a, b) => b.id.compareTo(a.id));
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _mudarStatus(Pedido p, String novoStatus) async {
    try {
      await PedidoService(_token).atualizarStatus(p.id, novoStatus);
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
    final nome = _sessao?['nome'] ?? 'Admin';
    final pendentes = _pedidos.where((p) => p.status == 'pendente').length;
    final emPreparo = _pedidos.where((p) => p.status == 'em_preparo').length;
    final entregues = _pedidos.where((p) => p.status == 'entregue').length;
    final faturamento = _pedidos.where((p) => p.status == 'entregue').fold(0.0, (s, p) => s + p.total);

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        title: const Text('Dashboard Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _carregar),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().logout();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFEF4444),
          labelColor: const Color(0xFFEF4444),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.receipt_long, size: 18),
                const SizedBox(width: 6),
                const Text('Pedidos'),
                if (pendentes > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                    child: Text('$pendentes', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ]),
            ),
            const Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Produtos'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : Column(children: [
              // Stats bar
              Container(
                color: const Color(0xFF27272A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Olá, $nome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _stat('$pendentes', 'Pendentes', const Color(0xFFF59E0B), Icons.hourglass_top_outlined),
                    const SizedBox(width: 8),
                    _stat('$emPreparo', 'Em Preparo', const Color(0xFF3B82F6), Icons.local_fire_department_outlined),
                    const SizedBox(width: 8),
                    _stat('$entregues', 'Entregues', const Color(0xFF10B981), Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    _stat('R\$${faturamento.toStringAsFixed(0)}', 'Faturamento', const Color(0xFFEF4444), Icons.attach_money),
                  ]),
                ]),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_abaPedidos(), _abaProdutos()],
                ),
              ),
            ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF4444),
        onPressed: () {
          if (_tabController.index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProdutosScreen())).then((_) => _carregar());
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _stat(String valor, String label, Color cor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Icon(icon, color: cor, size: 18),
          const SizedBox(height: 2),
          Text(valor, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ]),
      ),
    );
  }

  Widget _abaPedidos() {
    if (_pedidos.isEmpty) {
      return const Center(child: Text('Nenhum pedido.', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      color: const Color(0xFFEF4444),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pedidos.length,
        itemBuilder: (ctx, i) => _pedidoCard(_pedidos[i]),
      ),
    );
  }

  Widget _pedidoCard(Pedido p) {
    final cor = _corStatus(p.status);
    final inicial = p.nomeUsuario.isNotEmpty ? p.nomeUsuario[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        // Cabeçalho
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF18181B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFEF4444),
              child: Text(inicial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nomeUsuario, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Pedido #${p.id}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ),
            Text('R\$ ${p.total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ]),
        ),
        // Itens
        if (p.itens.isNotEmpty)
          ...p.itens.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(_emoji(item.nomeProduto), style: const TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(item.nomeProduto, style: const TextStyle(color: Colors.white, fontSize: 12))),
              Text('${item.quantidade}x', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(width: 8),
              Text('R\$ ${item.total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          )),
        // Status + botões
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: cor)),
              child: Text(_labelStatus(p.status), style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            if (p.status == 'pendente')
              _actionBtn('Preparar', const Color(0xFF3B82F6), () => _mudarStatus(p, 'em_preparo')),
            if (p.status == 'em_preparo')
              _actionBtn('Entregar', const Color(0xFF10B981), () => _mudarStatus(p, 'entregue')),
            if (p.status != 'cancelado' && p.status != 'entregue') ...[
              const SizedBox(width: 6),
              _actionBtn('Cancelar', Colors.red, () => _mudarStatus(p, 'cancelado')),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(String label, Color cor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _abaProdutos() {
    if (_produtos.isEmpty) {
      return const Center(child: Text('Nenhum produto.', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      color: const Color(0xFFEF4444),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final crossCount = (constraints.maxWidth / 180).floor().clamp(2, 6);
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount, childAspectRatio: 0.85, crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            itemCount: _produtos.length,
            itemBuilder: (ctx, i) {
              final p = _produtos[i];
              return Container(
                decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Center(child: Text(_emoji(p.categoria), style: const TextStyle(fontSize: 36))),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.15), borderRadius: BorderRadius.circular(5)),
                          child: Text(p.categoria, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9)),
                        ),
                        const SizedBox(height: 3),
                        Text(p.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('R\$ ${p.preco.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                          if (p.estoque <= 5)
                            Text('Est: ${p.estoque}', style: const TextStyle(color: Colors.orange, fontSize: 10)),
                        ]),
                      ]),
                    ),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
