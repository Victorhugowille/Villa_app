import 'package:flutter/material.dart';

class PrivacyTermsScreen extends StatefulWidget {
  final String title;
  final String content;

  const PrivacyTermsScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<PrivacyTermsScreen> createState() => _PrivacyTermsScreenState();
}

class _PrivacyTermsScreenState extends State<PrivacyTermsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Verifica se chegou ao final da rolagem
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) { // Uma pequena margem
      if (!_scrolledToBottom) {
        setState(() {
          _scrolledToBottom = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              // Usamos um Scrollbar para o usuário ver o progresso
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                  child: Text(
                    widget.content,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ),
          ),
          // --- Barra inferior com o botão ---
          Container(
            padding: const EdgeInsets.all(20.0).copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 20.0,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_scrolledToBottom)
                  const Text(
                    'Role até o final para aceitar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Habilita/Desabilita o botão
                    backgroundColor: _scrolledToBottom
                        ? theme.primaryColor
                        : theme.disabledColor,
                  ),
                  // Define o onPressed como null se não tiver rolado
                  onPressed: _scrolledToBottom
                      ? () {
                          // Retorna 'true' para a tela de login
                          Navigator.of(context).pop(true);
                        }
                      : null,
                  child: Text(
                    'LI E ACEITO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _scrolledToBottom
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}