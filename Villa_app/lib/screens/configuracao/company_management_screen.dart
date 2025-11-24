// lib/screens/admin/company_management_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importe seu modelo Company. Ajuste o caminho se necessário.
import '../../data/app_data.dart' as app_data;

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

// Enum para as ações do menu
enum CompanyAction { suspend, reactivate, delete }

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  Future<List<app_data.Company>>? _companiesFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _companiesFuture = _fetchCompanies();
  }

  // Busca empresas que NÃO estão 'pendentes' (aprovadas, suspensas, etc.)
  Future<List<app_data.Company>> _fetchCompanies() async {
    try {
      final response = await supabase
          .from('companies')
          .select('*')
          // Pega todas exceto 'pending' (que estão na outra tela)
          // e 'rejected' (que foram recusadas)
          .inFilter('status', ['approved', 'suspended']);

      final companies = (response as List)
          .map((companyData) =>
              app_data.Company.fromJson(companyData as Map<String, dynamic>))
          .toList();

      // Ordena para mostrar aprovadas primeiro
      companies.sort((a, b) {
        if (a.status == 'approved' && b.status != 'approved') return -1;
        if (a.status != 'approved' && b.status == 'approved') return 1;
        return a.name.compareTo(b.name);
      });

      return companies;
    } catch (e) {
      debugPrint("Erro ao buscar empresas: $e");
      throw Exception("Erro ao buscar empresas: $e");
    }
  }

  // Atualiza o status (para suspender ou reativar)
  Future<void> _updateCompanyStatus(String companyId, String newStatus) async {
    try {
      await supabase
          .from('companies')
          .update({'status': newStatus}).eq('id', companyId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Empresa ${newStatus == 'suspended' ? 'suspensa' : 'reativada'} com sucesso!'),
            backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao atualizar status: ${error.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      _refreshList();
    }
  }

  // Deleta a empresa
  Future<void> _deleteCompany(String companyId) async {
    try {
      // ATENÇÃO: Isso pode falhar se houver RLS (Row Level Security)
      // ou Foreign Keys ativadas.
      await supabase.from('companies').delete().eq('id', companyId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Empresa excluída permanentemente!'),
            backgroundColor: Colors.red),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao excluir: ${error.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      _refreshList();
    }
  }

  // Diálogo de confirmação para exclusão
  void _showDeleteDialog(String companyId, String companyName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir Empresa?'),
          content: Text(
              'Atenção! Esta ação é irreversível e excluirá permanentemente a empresa "$companyName" e TODOS os seus dados associados (usuários, produtos, pedidos, etc.).\n\nTem certeza?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteCompany(companyId);
              },
              child: const Text('Excluir Permanentemente',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _refreshList() {
    if (mounted) {
      setState(() {
        _companiesFuture = _fetchCompanies();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Empresas'),
      ),
      body: FutureBuilder<List<app_data.Company>>(
        future: _companiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final companies = snapshot.data;
          if (companies == null || companies.isEmpty) {
            return const Center(
              child: Text('Nenhuma empresa aprovada ou suspensa.'),
            );
          }

          return ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              final isSuspended = company.status == 'suspended';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isSuspended
                    ? Colors.blueGrey.shade900.withOpacity(0.5)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (company.logoUrl != null &&
                            company.logoUrl!.isNotEmpty)
                        ? NetworkImage(company.logoUrl!)
                        : null,
                    child: (company.logoUrl == null ||
                            company.logoUrl!.isEmpty)
                        ? const Icon(Icons.business)
                        : null,
                  ),
                  title: Text(company.name,
                      style: TextStyle(
                          decoration: isSuspended
                              ? TextDecoration.lineThrough
                              : TextDecoration.none)),
                  subtitle: Text(
                      'CNPJ: ${company.cnpj ?? 'N/A'}\nStatus: ${company.status}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<CompanyAction>(
                    onSelected: (CompanyAction action) {
                      switch (action) {
                        case CompanyAction.suspend:
                          _updateCompanyStatus(company.id, 'suspended');
                          break;
                        case CompanyAction.reactivate:
                          _updateCompanyStatus(company.id, 'approved');
                          break;
                        case CompanyAction.delete:
                          _showDeleteDialog(company.id, company.name);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        if (!isSuspended)
                          const PopupMenuItem<CompanyAction>(
                            value: CompanyAction.suspend,
                            child: Text('Suspender Acesso'),
                          ),
                        if (isSuspended)
                          const PopupMenuItem<CompanyAction>(
                            value: CompanyAction.reactivate,
                            child: Text('Reativar Acesso'),
                          ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<CompanyAction>(
                          value: CompanyAction.delete,
                          child: Text('Excluir Empresa',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ];
                    },
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