import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../data/cardapio_mock.dart';
import '../services/auth_service.dart';
import 'adicionar_produto_screen.dart';

// Tela do cardápio. Usa DefaultTabController para criar 3 abas:
// Lanches, Bebidas e Porções. Cada aba mostra uma grade de produtos.
class CardapioScreen extends StatelessWidget {
  const CardapioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController fornece o controlador para a TabBar e o TabBarView.
    return DefaultTabController(
      length: 3, // 3 abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cardápio'),
          actions: [
            // Botão de logout: chama o AuthService e volta para a tela de login.
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: () async {
                await AuthService().logout();
                // Remove todas as telas e leva para a raiz (login).
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.deepOrange,
            onPressed: () {
              // Abre a tela de cadastro de novo produto
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdicionarProdutoScreen()),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
          // Abas no rodapé do AppBar.
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.lunch_dining), text: 'Lanches'),
              Tab(icon: Icon(Icons.local_drink),  text: 'Bebidas'),
              Tab(icon: Icon(Icons.restaurant),   text: 'Porções'),
            ],
          ),
        ),
        // Cada TabBarView corresponde a uma aba na mesma ordem.
        body: TabBarView(
          children: [
            _ListaProdutos(categoria: 'lanches'),
            _ListaProdutos(categoria: 'bebidas'),
            _ListaProdutos(categoria: 'porcoes'),
          ],
        ),
      ),
    );
  }
}

// Widget privado (prefixo "_") que recebe uma categoria e
// monta a grade de produtos filtrando o cardápio mock.
class _ListaProdutos extends StatelessWidget {
  final String categoria;
  const _ListaProdutos({required this.categoria});

  @override
  Widget build(BuildContext context) {
    // Filtra apenas os produtos da categoria desta aba.
    final produtos =
        cardapioMock.where((p) => p.categoria == categoria).toList();

    if (produtos.isEmpty) {
      return const Center(child: Text('Nenhum produto cadastrado'));
    }

    // GridView.builder cria os cards em uma grade de 2 colunas.
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,        // 2 colunas
        crossAxisSpacing: 12,     // espaço horizontal entre os cards
        mainAxisSpacing: 12,      // espaço vertical
        childAspectRatio: 0.75,   // proporção (largura/altura) do card
      ),
      itemCount: produtos.length,
      itemBuilder: (context, index) => _CardProduto(produto: produtos[index]),
    );
  }
}

// Card visual de um produto: imagem no topo, nome e preço embaixo.
class _CardProduto extends StatelessWidget {
  final Produto produto;
  const _CardProduto({required this.produto});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // recorta a imagem nas bordas arredondadas
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // Por enquanto só mostra um SnackBar; depois pode abrir detalhes/carrinho.
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selecionado: ${produto.nome}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem do produto. Expanded faz ocupar o espaço disponível.
            Expanded(
              child: Image.network(
                produto.imagem,
                fit: BoxFit.cover,
                // Placeholder enquanto carrega.
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                // Caso a URL falhe, mostra um ícone genérico.
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image, size: 48),
              ),
            ),
            // Nome e preço dentro de um Padding para respirar.
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Formata o preço como "R\$ 18,90".
                    'R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
