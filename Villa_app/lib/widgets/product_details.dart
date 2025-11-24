// lib/widgets/product_details.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_data.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import '../screens/management/product_edit_screen.dart';

class ProductDetails extends StatelessWidget {
  final Product? product;

  const ProductDetails({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Selecione um produto à esquerda',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(product!.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Produto',
            onPressed: () {
              Provider.of<NavigationProvider>(context, listen: false)
                  .navigateTo(context, ProductEditScreen(product: product),
                      'Editar: ${product?.name}');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: product!.imageUrl != null
                      ? NetworkImage(product!.imageUrl!)
                      : null,
                  child: product!.imageUrl == null
                      ? const Icon(Icons.fastfood, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('R\$ ${product!.price.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor)),
                    const SizedBox(height: 4),
                    if (product!.isSoldOut)
                      Text('ESGOTADO',
                          style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Grupos de Adicionais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<GrupoAdicional>>(
                future: Provider.of<ProductProvider>(context, listen: false)
                    .getGruposAdicionaisParaProduto(product!.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('Nenhum grupo de adicionais encontrado.'));
                  }
                  final grupos = snapshot.data!;
                  return ListView.builder(
                    itemCount: grupos.length,
                    itemBuilder: (ctx, index) {
                      final grupo = grupos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundImage: (grupo.imageUrl != null
                                ? NetworkImage(grupo.imageUrl!)
                                : null) as ImageProvider?,
                            child: grupo.imageUrl == null
                                ? const Icon(Icons.layers)
                                : null,
                          ),
                          title: Text(grupo.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          children: grupo.adicionais.map((adicional) {
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundImage: (adicional.imageUrl != null
                                    ? NetworkImage(adicional.imageUrl!)
                                    : null) as ImageProvider?,
                                child: adicional.imageUrl == null
                                    ? const Icon(Icons.add, size: 18)
                                    : null,
                              ),
                              title: Text(adicional.name),
                              trailing: Text(
                                  'R\$ ${adicional.price.toStringAsFixed(2)}'),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}