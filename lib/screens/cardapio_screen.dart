import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'adicionar_produto_screen.dart';
import 'carrinho_screen.dart';
import 'perfil_screen.dart';

class CardapioScreen extends StatefulWidget {
  const CardapioScreen({super.key});

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // E-mail administrativo para controle de acesso (RF03)
  final String _emailAdmin = "191508@upf.br"; 

  // Função para gerenciar a adição/remoção de itens diretamente no Firestore
  Future<void> _alterarQuantidadeNoCarrinho(Map<String, dynamic> produto, int mudanca) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Referência para o documento do produto dentro do carrinho do usuário atual
    final docRef = _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('carrinho')
        .doc(produto['id']);

    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final int qtdAtual = (docSnap.data()?['quantidade'] ?? 0).toInt();
      final int novaQtd = qtdAtual + mudanca;

      if (novaQtd <= 0) {
        await docRef.delete();
      } else {
        await docRef.update({'quantidade': novaQtd});
      }
    } else if (mudanca > 0) {
      // Se o produto não estava no carrinho e clicou em "+", adiciona o primeiro
      await docRef.set({
        'id': produto['id'],
        'nome': produto['nome'],
        'preco': produto['preco'],
        'quantidade': 1,
        'adicionadoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _auth.currentUser?.email == _emailAdmin;
    final uid = _auth.currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BOM GOSTO'),
          centerTitle: true,
          actions: [
            // Botão do Carrinho (Navegação para gerenciamento do checkout)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Carrinho de Compras',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CarrinhoScreen()),
                );
              },
            ),
            // Botão do Perfil (Edição cadastral HU04)
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Meu Perfil',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PerfilScreen()),
                );
              },
            ),
            // Botão Administrativo (Visível apenas para o e-mail cadastrado)
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Adicionar Produto',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdicionarProdutoScreen()),
                  );
                },
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lanches'),
              Tab(text: 'Porções'),
              Tab(text: 'Bebidas'),
            ],
          ),
        ),
        body: uid == null
            ? const Center(child: Text('Por favor, faça login para ver o cardápio.'))
            : TabBarView(
                children: [
                  _buildListaCardapio('Lanches', uid),
                  _buildListaCardapio('Porções', uid),
                  _buildListaCardapio('Bebidas', uid),
                ],
              ),
      ),
    );
  }

  Widget _buildListaCardapio(String categoria, String uid) {
    // Escuta simultaneamente a coleção de produtos e a subcoleção de carrinho do usuário
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('produtos')
          .where('categoria', isEqualTo: categoria)
          .where('disponivel', isEqualTo: true)
          .snapshots(),
      builder: (context, produtosSnapshot) {
        if (produtosSnapshot.hasError) return const Center(child: Text('Erro ao carregar cardápio.'));
        if (produtosSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final produtosDocs = produtosSnapshot.data?.docs ?? [];
        if (produtosDocs.isEmpty) return const Center(child: Text('Nenhum item disponível.'));

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('usuarios').doc(uid).collection('carrinho').snapshots(),
          builder: (context, carrinhoSnapshot) {
            // Mapeia os IDs dos produtos do carrinho com suas respectivas quantidades atuais
            Map<String, int> quantidadesNoCarrinho = {};
            if (carrinhoSnapshot.hasData) {
              for (var doc in carrinhoSnapshot.data!.docs) {
                quantidadesNoCarrinho[doc.id] = (doc.get('quantidade') ?? 0).toInt();
              }
            }

            return ListView.builder(
              itemCount: produtosDocs.length,
              itemBuilder: (context, index) {
                final doc = produtosDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                // Consolida os dados essenciais para transporte
                final Map<String, dynamic> produto = {
                  'id': doc.id,
                  'nome': data['nome'] ?? 'Sem nome',
                  'preco': (data['preco'] ?? 0.0).toDouble(),
                };
                
                final int qtdAtual = quantidadesNoCarrinho[produto['id']] ?? 0;

                return ListTile(
                  title: Text(produto['nome']),
                  subtitle: Text(data['descricao'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'R\$ ${produto['preco'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      
                      // Estrutura de Botões Inline para Controle Direto do Catálogo
                      if (qtdAtual > 0) ...[
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _alterarQuantidadeNoCarrinho(produto, -1),
                        ),
                        Text(
                          '$qtdAtual',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => _alterarQuantidadeNoCarrinho(produto, 1),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}