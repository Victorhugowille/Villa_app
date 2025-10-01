import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/screens/management/adicional_edit_screen.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class AdicionalManagementScreen extends StatelessWidget {
  const AdicionalManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gerenciar Adicionais',
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: productProvider.adicionais.length,
              itemBuilder: (ctx, index) {
                final adicional = productProvider.adicionais[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(adicional.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('R\$ ${adicional.price.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await productProvider.deleteAdicional(adicional.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                    ),
                    onTap: () {
                      navProvider.navigateTo(
                          context, AdicionalEditScreen(adicional: adicional), 'Editar Adicional');
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          navProvider.navigateTo(context, const AdicionalEditScreen(), 'Novo Adicional');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}