import 'package:flutter/material.dart';
import '../../services/produto_service.dart';
import '../../services/categoria_service.dart';
import '../../models/produto.dart';

class ProdutoFormScreen extends StatefulWidget {
  final String token;
  final Produto? produto;

  const ProdutoFormScreen({super.key, required this.token, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _estoqueCtrl = TextEditingController();
  final _imagemCtrl = TextEditingController();
  String? _categoriaSelecionada;
  List<String> _categorias = [];
  bool _ativo = true;
  bool _carregando = false;

  bool get _editando => widget.produto != null;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    if (_editando) {
      final p = widget.produto!;
      _nomeCtrl.text = p.nome;
      _precoCtrl.text = p.preco.toStringAsFixed(2);
      _descCtrl.text = p.descricao ?? '';
      _estoqueCtrl.text = p.estoque.toString();
      _imagemCtrl.text = p.imagemUrl ?? '';
      _categoriaSelecionada = p.categoria;
      _ativo = p.ativo;
    }
  }

  Future<void> _carregarCategorias() async {
    try {
      final cats = await CategoriaService(widget.token).listar();
      setState(() => _categorias = cats);
      if (_editando && _categoriaSelecionada != null && !cats.contains(_categoriaSelecionada)) {
        setState(() => _categorias = [_categoriaSelecionada!, ...cats]);
      }
    } catch (_) {}
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _carregando = true);
    final dados = {
      'nome': _nomeCtrl.text.trim(),
      'preco': double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0,
      'descricao': _descCtrl.text.trim(),
      'categoria': _categoriaSelecionada,
      'estoque': int.tryParse(_estoqueCtrl.text) ?? 0,
      'imagem_url': _imagemCtrl.text.trim(),
      'ativo': _ativo,
    };
    try {
      if (_editando) {
        await ProdutoService(widget.token).atualizar(widget.produto!.id, dados);
      } else {
        await ProdutoService(widget.token).criar(dados);
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

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _precoCtrl.dispose();
    _descCtrl.dispose();
    _estoqueCtrl.dispose();
    _imagemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_editando ? 'Editar Produto' : 'Novo Produto',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _campo(_nomeCtrl, 'Nome do produto', Icons.label_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null),
              const SizedBox(height: 14),
              _campo(_precoCtrl, 'Preço (ex: 12.50)', Icons.attach_money,
                  tipo: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o preço';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Preço inválido';
                    return null;
                  }),
              const SizedBox(height: 14),
              _campo(_estoqueCtrl, 'Estoque', Icons.inventory_outlined,
                  tipo: TextInputType.number,
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Estoque inválido' : null),
              const SizedBox(height: 14),
              _campo(_descCtrl, 'Descrição (opcional)', Icons.description_outlined, maxLines: 2),
              const SizedBox(height: 14),
              _campo(_imagemCtrl, 'URL da imagem (opcional)', Icons.image_outlined),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                dropdownColor: const Color(0xFF27272A),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Categoria', Icons.category_outlined),
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoriaSelecionada = v),
                hint: const Text('Selecione a categoria', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Produto ativo', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Switch(
                    value: _ativo,
                    activeThumbColor: const Color(0xFFEF4444),
                    onChanged: (v) => setState(() => _ativo = v),
                  ),
                ],
              ),
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
                      : Text(_editando ? 'Salvar Alterações' : 'Criar Produto',
                          style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? tipo, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
      validator: validator,
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
