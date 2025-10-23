import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconPicker extends StatelessWidget {
  final ValueChanged<IconData> onIconSelected;

  const IconPicker({super.key, required this.onIconSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lista de ícones combinando Material e FontAwesome
    final List<IconData> foodIcons = [
      // FontAwesome Icons
      FontAwesomeIcons.pepperHot,
      FontAwesomeIcons.martiniGlass,
      FontAwesomeIcons.beerMugEmpty,
      FontAwesomeIcons.burger,
      FontAwesomeIcons.cheese,
      FontAwesomeIcons.breadSlice,
      FontAwesomeIcons.utensils,
      FontAwesomeIcons.mugSaucer,
      FontAwesomeIcons.fish,
      FontAwesomeIcons.shrimp,
      FontAwesomeIcons.whiskeyGlass,
      FontAwesomeIcons.bowlRice,
      FontAwesomeIcons.plateWheat,
      FontAwesomeIcons.carrot,
      FontAwesomeIcons.bacon,
      FontAwesomeIcons.seedling,
      FontAwesomeIcons.leaf,
      FontAwesomeIcons.drumstickBite,
      FontAwesomeIcons.hotdog,
      FontAwesomeIcons.stroopwafel,
      FontAwesomeIcons.pizzaSlice,
      FontAwesomeIcons.glassWater,
      FontAwesomeIcons.candyCane,
      FontAwesomeIcons.jar,
      FontAwesomeIcons.cow,
      FontAwesomeIcons.lemon,
      FontAwesomeIcons.appleWhole,
      FontAwesomeIcons.bottleWater,
      FontAwesomeIcons.truck,
      FontAwesomeIcons.box,

      // Material Icons (os melhores da lista anterior)
      Icons.fastfood,
      Icons.local_bar,
      Icons.outdoor_grill,
      Icons.cake,
      Icons.local_pizza,
      Icons.restaurant,
      Icons.ramen_dining,
      Icons.icecream,
      Icons.local_cafe,
      Icons.wine_bar,
      Icons.liquor,
      Icons.takeout_dining,
      Icons.delivery_dining,
      Icons.breakfast_dining,
      Icons.flatware,
      Icons.shopping_bag,
      Icons.grass,
      Icons.whatshot,
      Icons.percent,
    ];

    // Ordenar a lista para facilitar a busca visual
    foodIcons.sort((a, b) => a.codePoint.compareTo(b.codePoint));

    return AlertDialog(
      backgroundColor: theme.dialogBackgroundColor,
      title: Text('Selecione um Ícone',
          style: TextStyle(color: theme.colorScheme.onSurface)),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: foodIcons.length,
          itemBuilder: (context, index) {
            final icon = foodIcons[index];
            return InkWell(
              onTap: () {
                onIconSelected(icon);
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(12),
              // ===== CORREÇÃO AQUI =====
              // O widget 'Icon' padrão sabe como lidar com
              // IconData do Material e do FontAwesome.
              child: Icon(icon, size: 28, color: theme.colorScheme.onSurface),
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