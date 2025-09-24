import 'package:flutter/material.dart';

class IconPicker extends StatelessWidget {
  final ValueChanged<IconData> onIconSelected;

  const IconPicker({super.key, required this.onIconSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<IconData> foodIcons = [
      Icons.fastfood,
      Icons.local_bar,
      Icons.outdoor_grill,
      Icons.cake,
      Icons.local_pizza,
      Icons.restaurant,
      Icons.ramen_dining,
      Icons.lunch_dining,
      Icons.tapas,
      Icons.kebab_dining,
      Icons.icecream,
      Icons.local_cafe,
      Icons.wine_bar,
      Icons.liquor,
      Icons.nightlife,
      Icons.set_meal,
      Icons.bakery_dining,
      Icons.brunch_dining,
      Icons.dinner_dining,
      Icons.egg,
    ];

    return AlertDialog(
      backgroundColor: theme.dialogBackgroundColor,
      title: Text('Selecione um Ícone', style: TextStyle(color: theme.colorScheme.onSurface)),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: foodIcons.length,
          itemBuilder: (context, index) {
            final icon = foodIcons[index];
            return InkWell(
              onTap: () {
                onIconSelected(icon);
                Navigator.of(context).pop();
              },
              child: Icon(icon, size: 30, color: theme.colorScheme.onSurface),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: theme.primaryColor)),
        )
      ],
    );
  }
}