import 'package:flutter/material.dart';
import 'create_company_screen.dart';
import 'join_company_screen.dart';

class SignUpSelectionScreen extends StatelessWidget {
  const SignUpSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fazer Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.business),
              label: const Text('Criar uma nova empresa'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const CreateCompanyScreen(),
                ));
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Entrar em uma empresa existente'),
               onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const JoinCompanyScreen(),
                ));
              },
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}