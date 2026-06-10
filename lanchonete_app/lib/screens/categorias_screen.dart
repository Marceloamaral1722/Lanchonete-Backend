import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/categoria_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  List<String> _categorias = [];
  bool _carregando = true;

  static const _emojis = {
    'lanche': '🍔',
    'burguer': '🍔',
    'bebida': '🥤',
    'suco': '🥤',
    'sobremesa': '🍰',
    'sorvete': '🍦',
    'frita': '🍟',
    'combo': '🎁',
  };

  String _emoji(String cat) {
    final c = cat.toLowerCase();
    for (final entry in _emojis.entries) {
      if (c.contains(entry.key)) return entry.value;
    }
    return '🍽️';
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final sessao = await AuthService().getSessao();
      final token = sessao?['token'];
      if (token != null) {
        _categorias = await CategoriaService(token).listar();
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Categorias', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _carregar),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _categorias.isEmpty
              ? const Center(child: Text('Nenhuma categoria encontrada.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categorias.length,
                  itemBuilder: (ctx, i) {
                    final cat = _categorias[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(_emoji(cat), style: const TextStyle(fontSize: 24))),
                        ),
                        title: Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                ),
    );
  }
}
