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
  Future<List<Map<String, dynamic>>>? _requestsFuture; // Alterado para ser anulável
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // A busca é chamada diretamente aqui, garantindo que a variável seja inicializada.
    _requestsFuture = _fetchPendingRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingRequests() async {
    // Usar 'context.read' é mais seguro dentro de métodos como este
    final companyId = context.read<CompanyProvider>().currentCompany?.id;

    if (companyId == null) {
      // Espera um pouco e tenta de novo, caso o provider ainda não tenha carregado
      await Future.delayed(const Duration(milliseconds: 500));
      final refreshedCompanyId = context.read<CompanyProvider>().currentCompany?.id;
      if (refreshedCompanyId == null) {
        throw 'Empresa não encontrada para o usuário atual.';
      }
      return _fetchPendingRequests(); // Tenta a busca novamente
    }

    final response = await supabase
        .from('join_requests')
        .select()
        .eq('target_company_id', companyId)
        .eq('status', 'pending');

    return response;
  }
  
  Future<void> _approveRequest(String requestId) async {
    try {
      await supabase.functions.invoke('approve-join-request', body: {'request_id': requestId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário aprovado com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (error) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aprovar: ${error.toString()}'), backgroundColor: Colors.red),
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
      await supabase.from('join_requests').update({'status': 'rejected'}).eq('id', requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação reprovada.'), backgroundColor: Colors.orange),
      );
    } catch (error) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reprovar: ${error.toString()}'), backgroundColor: Colors.red),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-mail: ${request['requester_email']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Telefone: ${request['requester_phone']}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _rejectRequest(request['id']),
                            child: const Text('Reprovar', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _approveRequest(request['id']),
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