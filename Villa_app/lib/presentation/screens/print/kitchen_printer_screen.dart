import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/printer_provider.dart';

class KitchenPrinterScreen extends StatelessWidget {
  const KitchenPrinterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PrinterProvider>(
        builder: (context, printerProvider, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Monitorar e Imprimir Pedidos'),
                    value: printerProvider.isListening,
                    onChanged: (bool value) {
                      if (value) {
                        printerProvider.startListening();
                      } else {
                        printerProvider.stopListening();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Log de Impressão',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: printerProvider.logMessages.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(printerProvider.logMessages[index]),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        },
      )
    );
}
}