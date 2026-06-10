import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import 'admin/admin_home_screen.dart';
import 'cliente/cardapio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _carregando = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final sessao = await AuthService().getSessao();
    if (!mounted) return;
    if (sessao == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    setState(() {
      _isAdmin = sessao['tipo'] == 'admin';
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: Color(0xFF18181B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))),
      );
    }
    return _isAdmin ? const AdminHomeScreen() : const CardapioScreen();
  }
}
