// lib/screens/admin/company_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/screens/configuracao/company_management_screen.dart'; // Importe a nova tela

class CompanyRequestsScreen extends StatefulWidget {
  const CompanyRequestsScreen({super.key});

  @override
  State<CompanyRequestsScreen> createState() => _CompanyRequestsScreenState();
}

class _CompanyRequestsScreenState extends State<CompanyRequestsScreen> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  final supabase = Supabase.instance.client; // Instância do Supabase

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetchRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchRequests() async {
    try {
      final response = await supabase
          .from('signup_requests')
          .select()
          .eq('status', 'pending');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar solicitações: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw Exception('Failed to load requests');
    }
  }

  void _refreshRequests() {
    setState(() {
      _requestsFuture = _fetchRequests();
    });
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await supabase.functions.invoke(
        'approve-new-company',
        body: {'request_id': requestId},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empresa aprovada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _refreshRequests();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aprovar: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await supabase
          .from('signup_requests')
          .update({'status': 'rejected'}).eq('id', requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação recusada.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _refreshRequests();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao recusar: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações de Empresas'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ocorreu um erro ao carregar os dados.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma solicitação pendente.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final requests = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshRequests(),
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['company_name'] ?? 'Nome não informado',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('CNPJ: ${request['company_cnpj'] ?? '-'}'),
                        Text('Email: ${request['user_email'] ?? '-'}'),
                        Text('Telefone: ${request['company_phone'] ?? '-'}'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _rejectRequest(request['id']),
                              child: const Text('Recusar',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _approveRequest(request['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Aprovar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      // --- BOTÃO (FAB) ADICIONADO ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CompanyManagementScreen(),
            ),
          );
        },
        tooltip: 'Gerenciar Empresas',
        child: const Icon(Icons.business_center),
      ),
    );
  }
}