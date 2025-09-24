/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:villabistromobile/services/printing_service.dart';

class ReceiptWidget extends StatelessWidget {
  final List<OrderItem> items;
  final String tableName;
  final double total;
  final double paperWidth;

  const ReceiptWidget({
    super.key,
    required this.items,
    required this.tableName,
    required this.total,
    required this.paperWidth,
  });

  @override
  Widget build(BuildContext context) {
    final widthInPixels = paperWidth * 3.7795275591;

    const textStyle = TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'monospace');
    const boldTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace');

    return Container(
      width: widthInPixels,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'VillaBistrô',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace'),
          ),
          Text(
            'Pedido da Mesa: $tableName',
            style: const TextStyle(fontSize: 20, color: Colors.black, fontFamily: 'monospace'),
          ),
          const Divider(color: Colors.black),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item', style: boldTextStyle),
              Text('Total', style: boldTextStyle),
            ],
          ),
          const Divider(color: Colors.black),
          for (var item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      style: textStyle,
                    ),
                  ),
                  Text(
                    'R\$ ${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: textStyle,
                  ),
                ],
              ),
            ),
          const Divider(color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')),
              Text(
                'R\$ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace'),
              ),
            ],
          ),
          const Divider(color: Colors.black),
          Text(
            DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(DateTime.now()),
            style: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}*/