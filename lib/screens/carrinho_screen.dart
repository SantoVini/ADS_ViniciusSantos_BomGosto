import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pagamento_screen.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Atualiza a quantidade do item no Firestore de forma síncrona/reativa
  Future<void> _atualizarQuantidade(String itemId, int novaQuantidade) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('carrinho')
        .doc(itemId);

    if (novaQuantidade <= 0) {
      // Se a quantidade for a zero ou menor, remove o item (HU02)
      await docRef.delete();
    } else {
      // Caso contrário, atualiza o número no banco de dados
      await docRef.update({'quantidade': novaQuantidade});
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Por favor, faça login para ver seu carrinho.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MEU CARRINHO'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('usuarios')
            .doc(uid)
            .collection('carrinho')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar o carrinho.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Seu carrinho está vazio 🛒',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Processamento do cálculo do total geral em tempo real (HU02)
          double totalGeral = 0.0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final double preco = (data['preco'] ?? 0.0).toDouble();
            final int quantidade = (data['quantidade'] ?? 1).toInt();
            totalGeral += preco * quantidade;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final double preco = (data['preco'] ?? 0.0).toDouble();
                    final int quantidade = (data['quantidade'] ?? 1).toInt();

                    return ListTile(
                      title: Text(data['nome'] ?? 'Sem nome'),
                      subtitle: Text('R\$ ${preco.toStringAsFixed(2)} cada'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botão de Remover / Decrementar (-)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _atualizarQuantidade(doc.id, quantidade - 1),
                          ),

                          // Exibição da quantidade atualizada
                          Text(
                            '$quantidade',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Botão de Adicionar / Incrementar (+)
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.green,
                            ),
                            onPressed: () =>
                                _atualizarQuantidade(doc.id, quantidade + 1),
                          ),
                          const SizedBox(width: 8),

                          // Valor total do item (Preço * Quantidade)
                          Text(
                            'R\$ ${(preco * quantidade).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Painel de finalização fixado na parte de baixo
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'R\$ ${totalGeral.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        // Coleta a lista atual de itens mapeados para injetar na tela de pagamento
                        List<Map<String, dynamic>> itensDoPedido = docs.map((
                          doc,
                        ) {
                          final data = doc.data() as Map<String, dynamic>;
                          return {
                            'id_produto': doc.id,
                            'nome': data['nome'],
                            'preco': data['preco'],
                            'quantidade': data['quantidade'],
                          };
                        }).toList();

                        // Navega empurrando o valor calculado dinamicamente e a lista estruturada
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PagamentoScreen(
                              valorTotal: totalGeral,
                              itensPedido: itensDoPedido,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'AVANÇAR PARA O PAGAMENTO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
