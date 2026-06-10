import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/produtos/produtos_screen.dart';
import '../screens/pedidos/pedidos_screen.dart';
import '../screens/categorias_screen.dart';

class AppDrawer extends StatelessWidget {
  final String nome;
  final String email;
  final String tipo;

  const AppDrawer({
    super.key,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF18181B),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF27272A)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFEF4444),
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tipo == 'admin' ? const Color(0xFFEF4444) : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tipo == 'admin' ? 'Admin' : 'Cliente',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          _tile(context, Icons.home, 'Início', () => Navigator.pop(context)),
          _tile(context, Icons.inventory_2_outlined, 'Produtos', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProdutosScreen()));
          }),
          _tile(context, Icons.receipt_long_outlined, 'Pedidos', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PedidosScreen()));
          }),
          _tile(context, Icons.category_outlined, 'Categorias', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriasScreen()));
          }),
          const Divider(color: Color(0xFF3F3F46)),
          _tile(context, Icons.logout, 'Sair', () async {
            await AuthService().logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            }
          }, cor: const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  ListTile _tile(BuildContext context, IconData icon, String titulo, VoidCallback onTap, {Color? cor}) {
    return ListTile(
      leading: Icon(icon, color: cor ?? Colors.grey),
      title: Text(titulo, style: TextStyle(color: cor ?? Colors.white)),
      onTap: onTap,
    );
  }
}
