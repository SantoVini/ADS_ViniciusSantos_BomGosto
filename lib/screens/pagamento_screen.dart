import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cardapio_screen.dart';

class PagamentoScreen extends StatefulWidget {
  final double valorTotal;
  final List<Map<String, dynamic>> itensPedido;

  const PagamentoScreen({
    super.key,
    required this.valorTotal,
    required this.itensPedido,
  });

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formaPagamentoSelecionada = 'PIX';
  bool _processando = false;

  // Função simulando a comunicação segura com o Asaas via seu Backend Node.js
  Future<void> _processarPagamentoAsaas() async {
    setState(() {
      _processando = true;
    });

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Busca os dados cadastrais (Nome, Endereço) para enviar ao Asaas
      DocumentSnapshot userDoc = await _firestore
          .collection('usuarios')
          .doc(uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      final String nomeCliente = userData?['nome'] ?? 'Cliente Anônimo';
      final String enderecoEntrega = userData?['endereco'] ?? 'Não informado';

      // 2. Cria o registro unificado e oficial na coleção global de 'pedidos'
      final pedidoRef = _firestore.collection('pedidos').doc();

      await pedidoRef.set({
        'id_pedido': pedidoRef.id,
        'id_cliente': uid,
        'nome_cliente': nomeCliente,
        'endereco': enderecoEntrega,
        'itens': widget.itensPedido,
        'valor_total': widget.valorTotal,
        'forma_pagamento': _formaPagamentoSelecionada,
        'status': 'Pendente', // Inicia aguardando confirmação do Asaas
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // 3. Aqui seu Backend Node.js dispararia a rota do Asaas:
      // Ex: POST https://sandbox.asaas.com/v3/payments (Passando Nome, CPF, Valor e Tipo)

      // Simulação de retorno com base no método escolhido:
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simula latência de rede (RNF02)

      if (!mounted) return;

      // Limpa o carrinho rascunho temporário do usuário após consolidar o pedido
      final carrinhoDocs = await _firestore
          .collection('usuarios')
          .doc(uid)
          .collection('carrinho')
          .get();
      for (var doc in carrinhoDocs.docs) {
        await doc.reference.delete();
      }

      // Exibe feedback ou direciona para a tela com a chave Pix/Cartão do Asaas
      _exibirSucessoOuCopiaCola(pedidoRef.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar com o gateway Asaas: $e')),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  void _exibirSucessoOuCopiaCola(String pedidoId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PEDIDO CONFIRMADO! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pedido ID: $pedidoId'),
            const SizedBox(height: 12),
            if (_formaPagamentoSelecionada == 'PIX') ...[
              const Text(
                'Copia e Cola gerado pelo Asaas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: const Text(
                  '00020126360014BR.GOV.BCB.PIX0114asaasKey123456789...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ] else ...[
              const Text(
                'Sua cobrança em cartão foi enviada ao gateway com sucesso.',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o modal
              // Volta para o Cardápio limpando as telas anteriores
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const CardapioScreen()),
                (route) => false,
              );
            },
            child: const Text('OK, VOLTAR AO INÍCIO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PAGAMENTO (ASAAS)'), centerTitle: true),
      body: _processando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Comunicando com o Asaas e registrando pedido...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo de Valores:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.amber[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a pagar:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'R\$ ${widget.valorTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Escolha o método de pagamento:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Opção PIX Asaas
                  RadioListTile<String>(
                    title: const Text('PIX (Aprovação Imediata via Asaas)'),
                    value: 'PIX',
                    groupValue: _formaPagamentoSelecionada,
                    onChanged: (value) {
                      setState(() {
                        _formaPagamentoSelecionada = value!;
                      });
                    },
                  ),

                  // Opção Cartão Asaas
                  RadioListTile<String>(
                    title: const Text('Cartão de Crédito Online'),
                    value: 'Cartão de Crédito',
                    groupValue: _formaPagamentoSelecionada,
                    onChanged: (value) {
                      setState(() {
                        _formaPagamentoSelecionada = value!;
                      });
                    },
                  ),

                  // Opção Na Entrega
                  RadioListTile<String>(
                    title: const Text('Pagar na Entrega (Maquininha/Dinheiro)'),
                    value: 'Na Entrega',
                    groupValue: _formaPagamentoSelecionada,
                    onChanged: (value) {
                      setState(() {
                        _formaPagamentoSelecionada = value!;
                      });
                    },
                  ),

                  const Spacer(),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    onPressed: _processarPagamentoAsaas,
                    child: const Text(
                      'CONFIRMAR E GERAR COBRANÇA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
