import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pagamento_screen.dart'; // Preparado para o seu próximo passo do Asaas

class CarrinhoScreen extends StatelessWidget {
  CarrinhoScreen({Key? key}) : super(key: key); // Construtor com Key corrigido!

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final String? uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho'),
        centerTitle: true,
      ),
      body: uid == null
          ? const Center(child: Text('Por favor, faça login para ver seu carrinho.'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('usuarios')
                  .doc(uid)
                  .collection('carrinho')
                  .orderBy('adicionadoEm', descending: false) // Organiza por ordem de adição
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Seu carrinho está vazio.'));
                }

                final itensCarrinho = snapshot.data!.docs;
                double totalCarrinho = 0.0;

                // Calcula o valor total dinamicamente em tempo real (RF02 / HU02)
                for (var doc in itensCarrinho) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final double preco = (dados['preco'] ?? 0.0).toDouble();
                  final int quantidade = (dados['quantidade'] ?? 1).toInt();
                  totalCarrinho += preco * quantidade;
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: itensCarrinho.length,
                        itemBuilder: (context, index) {
                          final doc = itensCarrinho[index];
                          final item = doc.data() as Map<String, dynamic>;

                          // Chaves perfeitamente alinhadas com o CardapioScreen!
                          final String idProduto = item['id'] ?? doc.id;
                          final String nome = item['nome'] ?? 'Produto sem nome';
                          final double preco = (item['preco'] ?? 0.0).toDouble();
                          final int quantidade = (item['quantidade'] ?? 1).toInt();

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('R\$ ${preco.toStringAsFixed(2)} x $quantidade'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'R\$ ${(preco * quantidade).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () async {
                                      // Permite remover direto do carrinho se o cliente quiser
                                      await _firestore
                                          .collection('usuarios')
                                          .doc(uid)
                                          .collection('carrinho')
                                          .doc(idProduto)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Painel de Fechamento de Valor Geral (HU03)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 5)
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            'R\$ ${totalCarrinho.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}