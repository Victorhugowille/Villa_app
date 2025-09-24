import 'package:flutter/material.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/screens/category_management_screen.dart';
import 'package:villabistromobile/screens/product_management_screen.dart';
import 'package:villabistromobile/screens/table_management_screen.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Gestão'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildManagementCard(
            context: context,
            icon: Icons.restaurant_menu,
            title: 'Gerenciar Produtos',
            onTap: () {
              NavigationProvider.navigateTo(
                  context, const ProductManagementScreen());
            },
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            icon: Icons.category,
            title: 'Gerenciar Categorias',
            onTap: () {
              NavigationProvider.navigateTo(
                  context, const CategoryManagementScreen());
            },
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            icon: Icons.table_restaurant,
            title: 'Gerenciar Mesas',
            onTap: () {
              NavigationProvider.navigateTo(
                  context, const TableManagementScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      color: theme.primaryColor.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: theme.primaryColor, size: 40),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            color: theme.colorScheme.onBackground),
        onTap: onTap,
      ),
    );
  }
}