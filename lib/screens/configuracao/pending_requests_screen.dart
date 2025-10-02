import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/providers/company_provider.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  Future<List<Map<String, dynamic>>>? _requestsFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetchPendingRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingRequests() async {
    final companyId = context.read<CompanyProvider>().currentCompany?.id;
    if (companyId == null) {
      throw 'Empresa não encontrada para o usuário atual.';
    }

    final response = await supabase
        .from('join_requests')
        .select()
        .eq('target_company_id', companyId)
        .eq('status', 'pending');

    return response;
  }

  // NOVA FUNÇÃO: Mostra o diálogo para escolher o cargo
  void _showApprovalDialog(String requestId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String selectedRole = 'employee'; // Cargo padrão
        return AlertDialog(
          title: const Text('Aprovar Usuário'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecione o cargo para este usuário:'),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'employee',
                        child: Text('Funcionário'),
                      ),
                      DropdownMenuItem(
                        value: 'owner',
                        child: Text('Sócio (Patrão)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _approveRequest(requestId, selectedRole); // Chama a aprovação com o cargo
              },
              child: const Text('Aprovar'),
            ),
          ],
        );
      },
    );
  }

  // Função de aprovação agora aceita o cargo
  Future<void> _approveRequest(String requestId, String role) async {
    try {
      await supabase.functions.invoke('approve-join-request', body: {
        'request_id': requestId,
        'role': role, // Envia o cargo para a Edge Function
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Usuário aprovado com sucesso!'),
            backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao aprovar: ${error.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _requestsFuture = _fetchPendingRequests();
        });
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await supabase
          .from('join_requests')
          .update({'status': 'rejected'}).eq('id', requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Solicitação reprovada.'),
            backgroundColor: Colors.orange),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao reprovar: ${error.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _requestsFuture = _fetchPendingRequests();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações Pendentes'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final requests = snapshot.data;
          if (requests == null || requests.isEmpty) {
            return const Center(
              child: Text('Nenhuma solicitação pendente no momento.'),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-mail: ${request['requester_email']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Telefone: ${request['requester_phone']}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _rejectRequest(request['id']),
                            child: const Text('Reprovar',
                                style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            // O botão agora chama o diálogo
                            onPressed: () => _showApprovalDialog(request['id']),
                            child: const Text('Aprovar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}