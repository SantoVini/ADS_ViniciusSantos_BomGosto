import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// Tela onde o dono do restaurante cadastra um novo produto no cardápio
class AdicionarProdutoScreen extends StatefulWidget {
  const AdicionarProdutoScreen({super.key});

  @override
  State<AdicionarProdutoScreen> createState() => _AdicionarProdutoScreenState();
}

class _AdicionarProdutoScreenState extends State<AdicionarProdutoScreen> {
  // Chave do formulário usada para validar todos os campos de uma vez
  final _formKey = GlobalKey<FormState>();

  // Controllers que guardam o texto digitado em cada campo
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();

  // Categoria selecionada no Dropdown (lanches, bebidas ou porcoes)
  String _categoria = 'lanches';

  // Arquivo da imagem escolhida da galeria (ainda não enviada ao Firebase)
  File? _imagem;

  // Controla o spinner do botão "Salvar" enquanto envia ao Firebase
  bool _salvando = false;

  // Abre a galeria do celular e guarda a imagem selecionada na variável _imagem
  Future<void> _escolherImagem() async {
    final picker = ImagePicker();
    final XFile? arquivo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // comprime para subir mais rápido
    );

    if (arquivo != null) {
      setState(() => _imagem = File(arquivo.path));
    }
  }

  // Faz upload da imagem para o Firebase Storage e devolve a URL pública
  Future<String> _uploadImagem(File arquivo) async {
    // Cria um nome único usando o timestamp atual
    final nomeArquivo = 'produtos/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Referência no Storage onde o arquivo será salvo
    final ref = FirebaseStorage.instance.ref().child(nomeArquivo);

    // Envia o arquivo
    await ref.putFile(arquivo);

    // Retorna a URL pública para salvar no Firestore
    return await ref.getDownloadURL();
  }

  // Valida o formulário, sobe a imagem e grava o produto no Firestore
  Future<void> _salvarProduto() async {
    // Valida todos os TextFormField
    if (!_formKey.currentState!.validate()) return;

    // Garante que o usuário escolheu uma imagem
    if (_imagem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      // 1) Sobe a imagem e pega a URL
      final urlImagem = await _uploadImagem(_imagem!);

      // 2) Converte o preço de "12,50" para 12.50 (double)
      final preco = double.parse(
        _precoController.text.replaceAll(',', '.'),
      );

      // 3) Salva o documento na coleção "produtos" do Firestore
      await FirebaseFirestore.instance.collection('produtos').add({
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'preco': preco,
        'imagem': urlImagem,
        'categoria': _categoria,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Avisa o usuário e volta para a tela anterior
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      // Mostra qualquer erro de upload/gravação na tela
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // Libera a memória dos controllers quando a tela é destruída
  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Produto'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área que mostra a imagem escolhida ou um botão para escolher
              GestureDetector(
                onTap: _escolherImagem,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imagem != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imagem!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Toque para escolher uma imagem'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Campo: nome do produto
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do produto',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              // Campo: descrição (multiline)
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Informe a descrição'
                    : null,
              ),
              const SizedBox(height: 16),

              // Campo: preço (apenas números e vírgula/ponto)
              TextFormField(
                controller: _precoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o preço';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Preço inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dropdown para escolher a categoria do produto
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'lanches', child: Text('Lanches')),
                  DropdownMenuItem(value: 'bebidas', child: Text('Bebidas')),
                  DropdownMenuItem(value: 'porcoes', child: Text('Porções')),
                ],
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 24),

              // Botão Salvar (mostra spinner enquanto envia)
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvarProduto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: _salvando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salvar produto',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
