// lib/screens/employee_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/providers/company_provider.dart';

// Enum para as ações do menu
enum EmployeeAction {
  suspend, // Suspender
  reactivate, // Reativar
  changeRole, // Mudar cargo (para dono ou funcionário)
  delete // Apagar
}

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  Future<List<Map<String, dynamic>>>? _employeesFuture;
  final supabase = Supabase.instance.client;
  String? _companyId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _companyId = context.read<CompanyProvider>().currentCompany?.id;
    _currentUserId = supabase.auth.currentUser?.id;

    if (_companyId != null && _currentUserId != null) {
      _employeesFuture = _fetchEmployees();
    }
  }

  // Busca funcionários (profiles) da empresa atual
  Future<List<Map<String, dynamic>>> _fetchEmployees() async {
    if (_companyId == null) throw Exception('ID da empresa não encontrado');
    if (_currentUserId == null) throw Exception('Usuário logado não encontrado');

    try {
      final response = await supabase
          .from('profiles')
          .select('user_id, full_name, role, status') // Busca tudo
          .eq('company_id', _companyId!)
          .neq('user_id', _currentUserId!); // Não listar o próprio usuário

      return (response as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar funcionários: $e");
      throw Exception("Erro ao buscar funcionários: $e");
    }
  }

  // --- FUNÇÃO DE SUSPENDER/REATIVAR (RESTAURADA) ---
  Future<void> _updateEmployeeStatus(String userId, String newStatus) async {
    try {
      await supabase
          .from('profiles')
          .update({'status': newStatus}).eq('user_id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Funcionário ${newStatus == 'suspended' ? 'suspenso' : 'reativado'}!'),
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

  // --- FUNÇÃO DE MUDAR O CARGO ---
  Future<void> _updateEmployeeRole(String userId, String newRole) async {
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole}).eq('user_id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Cargo do funcionário atualizado para $newRole!'),
            backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao atualizar cargo: ${error.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      _refreshList();
    }
  }

  // --- FUNÇÃO DE APAGAR ---
  Future<void> _deleteEmployeeProfile(String userId) async {
    try {
      await supabase.from('profiles').delete().eq('user_id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Funcionário removido da empresa!'),
            backgroundColor: Colors.red),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao remover funcionário: ${error.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      _refreshList();
    }
  }

  // Diálogo de confirmação para remoção
  void _showDeleteDialog(String userId, String? name) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover Funcionário?'),
          content: Text(
              'Você tem certeza que deseja remover "${name ?? 'este usuário'}" da sua empresa? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteEmployeeProfile(userId);
              },
              child: const Text('Remover',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _refreshList() {
    if (mounted && _companyId != null) {
      setState(() {
        _employeesFuture = _fetchEmployees();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_companyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestão de Funcionários')),
        body: const Center(
          child: Text('Erro: Empresa não identificada. Saia e entre novamente.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Funcionários'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final employees = snapshot.data;
          if (employees == null || employees.isEmpty) {
            return const Center(
              child: Text('Nenhum funcionário encontrado nesta empresa.'),
            );
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              final String name =
                  employee['full_name'] ?? 'Nome não informado';
              final String role = employee['role'] ?? 'não definido';
              final String status = employee['status'] ?? 'active';
              final isSuspended = status == 'suspended';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isSuspended
                    ? Colors.blueGrey.shade900.withOpacity(0.5)
                    : null,
                child: ListTile(
                  title: Text(name,
                      style: TextStyle(
                          decoration: isSuspended
                              ? TextDecoration.lineThrough
                              : TextDecoration.none)),
                  subtitle: Text(
                      'Cargo: $role\nStatus: $status'),
                  isThreeLine: true,
                  // --- MENU COM TODAS AS OPÇÕES ---
                  trailing: PopupMenuButton<EmployeeAction>(
                    onSelected: (EmployeeAction action) {
                      final userId = employee['user_id'] as String;
                      switch (action) {
                        case EmployeeAction.suspend:
                          _updateEmployeeStatus(userId, 'suspended');
                          break;
                        case EmployeeAction.reactivate:
                          _updateEmployeeStatus(userId, 'active');
                          break;
                        case EmployeeAction.changeRole:
                          // Define o NOVO cargo baseado no cargo ATUAL
                          final newRole =
                              (role == 'owner') ? 'employee' : 'owner';
                          _updateEmployeeRole(userId, newRole);
                          break;
                        case EmployeeAction.delete:
                          _showDeleteDialog(userId, name);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      // Lista dinâmica de widgets para o menu
                      final List<PopupMenuEntry<EmployeeAction>> menuItems = [];

                      // 1. Adiciona Suspender ou Reativar
                      if (isSuspended) {
                        menuItems.add(const PopupMenuItem<EmployeeAction>(
                          value: EmployeeAction.reactivate,
                          child: Text('Reativar Acesso'),
                        ));
                      } else {
                        menuItems.add(const PopupMenuItem<EmployeeAction>(
                          value: EmployeeAction.suspend,
                          child: Text('Suspender Acesso'),
                        ));
                      }

                      menuItems.add(const PopupMenuDivider());

                      // 2. Adiciona Mudar Cargo (para Dono ou Funcionário)
                      final String changeRoleText = (role == 'owner')
                          ? 'Rebaixar para Funcionário'
                          : 'Promover para Dono';

                      menuItems.add(PopupMenuItem<EmployeeAction>(
                        value: EmployeeAction.changeRole,
                        child: Text(changeRoleText),
                      ));

                      menuItems.add(const PopupMenuDivider());

                      // 3. Adiciona Apagar
                      menuItems.add(const PopupMenuItem<EmployeeAction>(
                        value: EmployeeAction.delete,
                        child: Text('Remover da Empresa',
                            style: TextStyle(color: Colors.red)),
                      ));

                      return menuItems;
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