// lib/screens/configuracao/delivery_zones_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/company_provider.dart';
import '../../../data/models/app_data.dart' as app_data;
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

// Modelo da Zona de Entrega (sem alterações)
class DeliveryZone {
  final String id;
  final String name;
  final int radiusMeters;
  final double fee;
  DeliveryZone({required this.id, required this.name, required this.radiusMeters, required this.fee});
  factory DeliveryZone.fromMap(Map<String, dynamic> map) {
    // Adiciona tratamento para ID que pode vir como int ou String do Supabase
    final idValue = map['id'];
    final String finalId = idValue is int ? idValue.toString() : (idValue ?? '');

    return DeliveryZone(
      id: finalId, // Usa o ID tratado
      name: map['name'] ?? 'Zona desconhecida', // Valor padrão para nome
      radiusMeters: (map['radius_meters'] as num?)?.toInt() ?? 0, // Tratamento para num nulo
      fee: (map['fee'] as num?)?.toDouble() ?? 0.0, // Tratamento para num nulo
    );
  }
}


class DeliveryZonesScreen extends StatefulWidget {
  const DeliveryZonesScreen({super.key});

  @override
  State<DeliveryZonesScreen> createState() => _DeliveryZonesScreenState();
}

class _DeliveryZonesScreenState extends State<DeliveryZonesScreen> {
  final MapController _mapController = MapController();

  List<DeliveryZone> _zones = [];
  app_data.Company? _company;
  LatLng? _savedCompanyLocation;
  LatLng? _selectedLocation;

  CircleMarker? _previewCircle;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Define um ponto de interrupção para mudar o layout
  final double _breakpoint = 700.0; // Ajuste este valor se necessário

  @override
  void initState() {
    super.initState();
    // Atraso mínimo para garantir que o context está pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         _loadData();
       }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
     // Verifica se o widget ainda está montado antes de operações async
     if (!mounted) return;
    setState(() => _isLoading = true);

    _company = context.read<CompanyProvider>().currentCompany;
    if (_company == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Dados da empresa não carregados.'))
        );
         setState(() => _isLoading = false);
      }
      return;
    }

    if (_company!.latitude != null && _company!.longitude != null) {
      _savedCompanyLocation = LatLng(_company!.latitude!, _company!.longitude!);
      // Move o mapa APENAS se ele não foi movido ainda pelo _centerOnMyLocation
        Future.delayed(const Duration(milliseconds: 100), () {
           if (mounted && _savedCompanyLocation != null) {
              // Tenta mover, mas sem forçar se o usuário já mexeu
              _mapController.move(_savedCompanyLocation!, 14.0);
           }
        });
    } else {
        await _centerOnMyLocation(showError: false);
    }

    await _fetchZones();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchZones() async {
    if (_company == null || !mounted) return;

    try {
      final response = await Supabase.instance.client
          .from('delivery_zones')
          .select()
          .eq('company_id', _company!.id)
          .order('radius_meters', ascending: true);

      if (mounted) {
        setState(() {
          _zones = response.map((map) => DeliveryZone.fromMap(map)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar zonas: ${e is PostgrestException ? e.message : e}'))
        );
      }
    }
  }


  Future<void> _saveSelectedLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toque no mapa para escolher uma localização antes de salvar.')));
      return;
    }
    if (_company == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client
          .from('companies')
          .update({'latitude': _selectedLocation!.latitude, 'longitude': _selectedLocation!.longitude})
          .eq('id', _company!.id);

      context.read<CompanyProvider>().updateLocalCompanyLocation(_selectedLocation!.latitude, _selectedLocation!.longitude);
      _company = context.read<CompanyProvider>().currentCompany;

      if(mounted){
          setState(() {
              _savedCompanyLocation = _selectedLocation;
              _selectedLocation = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Localização do restaurante salva com sucesso!'), backgroundColor: Colors.green,));
      }

    } catch (e) {
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao salvar localização: ${e is PostgrestException ? e.message : e}'))
          );
      }
    } finally {
        if(mounted){
            setState(() => _isLoading = false);
        }
    }
  }

 Future<bool> _handleLocationPermission() async {
    // Verifica se está montado no início
    if (!mounted) return false;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Verifica de novo antes de mostrar SnackBar
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serviços de localização estão desativados. Por favor, ative-os.')));
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão de localização negada.')));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão de localização negada permanentemente. Não podemos solicitar permissões.')));
      // Poderia abrir configurações do app aqui
      // Geolocator.openAppSettings();
      return false;
    }

    return true;
  }


  Future<void> _centerOnMyLocation({bool showError = true}) async {
      // Verifica se montado antes de tudo
      if (!mounted) return;

      final hasPermission = await _handleLocationPermission();
      // Verifica de novo após a permissão
      if (!hasPermission || !mounted) return;

      try {
        Position? position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);

        final myLocation = LatLng(position.latitude, position.longitude);
        if(mounted){
            _mapController.move(myLocation, 15.0);
        }
      } catch (e) {
        if (mounted && showError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar localização: $e')));
        }
      }
  }


  void _showZoneDialog({DeliveryZone? zone}) {
    // Verifica se a localização base está salva antes de abrir o dialog
    if (_savedCompanyLocation == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salve a localização do restaurante primeiro!'))
       );
       return;
    }

    final nameController = TextEditingController(text: zone?.name ?? '');
    final radiusController = TextEditingController(text: zone?.radiusMeters.toString() ?? '');

    final feeController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ',
      decimalSeparator: ',',
      thousandSeparator: '.', // Correção já aplicada
      initialValue: zone?.fee ?? 0.0
    );

    final formKey = GlobalKey<FormState>();

    void updatePreviewCircle() {
      final radius = int.tryParse(radiusController.text) ?? 0;
      if (_savedCompanyLocation != null && radius > 0 && mounted) {
           setState(() {
             _previewCircle = CircleMarker(
               point: _savedCompanyLocation!,
               radius: radius.toDouble(),
               useRadiusInMeter: true,
               color: Colors.orange.withOpacity(0.3),
               borderColor: Colors.orangeAccent,
               borderStrokeWidth: 1.5,
             );
           });
      } else {
         if (mounted) {
            setState(() => _previewCircle = null);
         }
      }
    }
    radiusController.addListener(updatePreviewCircle);
    updatePreviewCircle();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(zone == null ? 'Adicionar Nova Zona' : 'Editar Zona'),
          content: SingleChildScrollView( // <-- Garante rolagem no form
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome da Zona (Ex: Centro)'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: radiusController,
                      decoration: const InputDecoration(labelText: 'Raio (em metros)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                          if (v == null || v.isEmpty) return 'Raio é obrigatório';
                          final r = int.tryParse(v);
                          if (r == null || r <= 0) return 'Insira um número positivo';
                          return null;
                      }),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: feeController,
                      decoration: const InputDecoration(labelText: 'Taxa de Entrega (R\$)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                          if (v == null || v.isEmpty) return 'Taxa é obrigatória';
                           if (feeController.numberValue < 0) return 'Taxa não pode ser negativa';
                          return null;
                      }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                    Navigator.pop(context);
                },
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (!mounted) return; // Verifica antes da operação async

                final radius = int.parse(radiusController.text);
                final fee = feeController.numberValue;

                final data = {
                  'company_id': _company!.id,
                  'name': nameController.text.trim(),
                  'radius_meters': radius,
                  'fee': fee,
                };

                // Feedback visual de loading (opcional, pode ser no botão)
                // setState(() => _isLoading = true);

                try {
                  if (zone == null) {
                    await Supabase.instance.client.from('delivery_zones').insert(data);
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zona adicionada!'), backgroundColor: Colors.green));
                  } else {
                    await Supabase.instance.client.from('delivery_zones').update(data).eq('id', zone.id);
                     if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zona atualizada!'), backgroundColor: Colors.green));
                  }
                  if(mounted) Navigator.pop(context);
                  await _fetchZones(); // Recarrega as zonas
                } catch (e) {
                  if(mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao salvar zona: ${e is PostgrestException ? e.message : e}'))
                    );
                  }
                } finally {
                    // if(mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      }
    ).whenComplete(() {
        if (mounted) {
            setState(() => _previewCircle = null);
        }
        radiusController.removeListener(updatePreviewCircle);
        nameController.dispose();
        radiusController.dispose();
        feeController.dispose();
    });
  }

  Future<void> _deleteZone(DeliveryZone zone) async {
       if (!mounted) return;
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('Confirmar Exclusão'),
              content: Text('Tem certeza que deseja apagar a zona "${zone.name}"?'),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Apagar', style: TextStyle(color: Colors.red)),
                  ),
              ],
          ),
      );

      if (confirm == true && mounted) { // Verifica mounted novamente
          try {
              await Supabase.instance.client.from('delivery_zones').delete().eq('id', zone.id);
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zona apagada.'), backgroundColor: Colors.green));
                 await _fetchZones();
              }
          } catch (e) {
               if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao apagar zona: ${e is PostgrestException ? e.message : e}'))
                  );
               }
          }
      }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading && _company == null) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_company == null) {
       return const Scaffold(body: Center(child: Text('Erro ao carregar dados da empresa.')));
    }

    List<Marker> markers = [];
    List<CircleMarker> circles = [];

    if (_savedCompanyLocation != null) {
      markers.add(Marker(
        point: _savedCompanyLocation!,
        width: 80, height: 80, alignment: Alignment.topCenter, // Ajusta alinhamento
        child: Tooltip(
            message: 'Localização do Restaurante',
            child: Icon(Icons.storefront, color: Theme.of(context).primaryColor, size: 35),
        )
      ));
      circles = _zones.map((zone) => CircleMarker(
        point: _savedCompanyLocation!,
        radius: zone.radiusMeters.toDouble(),
        useRadiusInMeter: true,
        color: Colors.lightBlue.withOpacity(0.15),
        borderColor: Colors.blueAccent.withOpacity(0.5),
        borderStrokeWidth: 1.5,
      )).toList();
    }
    if (_selectedLocation != null) {
      markers.add(Marker(
        point: _selectedLocation!,
         width: 80, height: 80, alignment: Alignment.topCenter, // Ajusta alinhamento
        child: const Tooltip(
            message: 'Nova localização selecionada',
            child: Icon(Icons.location_on, color: Colors.green, size: 35),
        )
      ));
    }
    if (_previewCircle != null) {
      circles.add(_previewCircle!);
    }

    return Scaffold(
      appBar: AppBar(
         title: const Text('Configurar Zonas de Entrega'),
         // Ação para recarregar dados (opcional)
         // actions: [
         //    IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh), tooltip: 'Recarregar Dados')
         // ],
      ),
      // Usa LayoutBuilder para decidir entre Row e Column
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Verifica se a largura é menor que o breakpoint
          bool useColumnLayout = constraints.maxWidth < _breakpoint;

          // Conteúdo do Mapa (com botões sobrepostos)
          Widget mapContent = Stack(
             children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _savedCompanyLocation ?? const LatLng(-25.18, -54.06),
                    initialZoom: _savedCompanyLocation != null ? 14 : 12,
                    onTap: (_, pos) {
                       if (mounted) {
                           setState(() => _selectedLocation = pos);
                       }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.villabistromobile.app', // Substitua
                    ),
                    CircleLayer(circles: circles),
                    MarkerLayer(markers: markers),
                  ],
                ),
                Positioned(
                   bottom: 10,
                   right: 10,
                   child: FloatingActionButton(
                      heroTag: 'centerMapButton', // Tag única para o FAB
                      mini: true,
                      onPressed: _centerOnMyLocation,
                      tooltip: 'Centralizar na minha localização',
                      child: const Icon(Icons.my_location),
                   ),
                ),
             ],
          );

          // Conteúdo do Painel de Zonas
          Widget zonesContent = _buildZonesPanel();

          // Retorna Column ou Row baseado na largura
          if (useColumnLayout) {
            // Layout de Coluna para Telas Pequenas
            return Column(
              children: [
                 _buildLocationPanel(), // Painel de localização em cima
                 const Divider(height: 1, thickness: 1),
                 Expanded(flex: 3, child: mapContent), // Mapa
                 const Divider(height: 1, thickness: 1),
                 Expanded(flex: 2, child: zonesContent), // Zonas embaixo
              ],
            );
          } else {
            // Layout de Linha para Telas Maiores
            return Column( // Coluna principal para incluir o painel de localização
               children: [
                  _buildLocationPanel(),
                  const Divider(height: 1, thickness: 1),
                  Expanded( // O Row ocupa o espaço restante
                     child: Row(
                       children: [
                         Expanded(flex: 3, child: mapContent), // Mapa
                         const VerticalDivider(width: 1, thickness: 1),
                         Expanded(flex: 2, child: zonesContent), // Zonas
                       ],
                     ),
                  ),
               ],
            );
          }
        },
      ),
    );
  }


  // Painel de Localização (sem mudanças aqui)
  Widget _buildLocationPanel() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _savedCompanyLocation == null
              ? '📌 Defina a localização base do seu restaurante tocando no mapa.'
              : _selectedLocation == null
                 ? '📍 Localização salva. Toque no mapa para alterar.'
                 : '✅ Nova localização selecionada. Clique em Salvar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
              onPressed: _selectedLocation == null || _isLoading ? null : _saveSelectedLocation,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_alt),
              label: const Text('Salvar Localização do Restaurante'),
              style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.green,
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(vertical: 12),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  // Painel de Zonas (sem mudanças aqui)
  Widget _buildZonesPanel() {
    if (_savedCompanyLocation == null) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Salve a localização do restaurante no mapa para poder gerenciar as zonas de entrega.', textAlign: TextAlign.center),
          ));
    }
    if (_isLoading && _zones.isEmpty) {
        return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
         Padding(
           padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text('Zonas de Entrega', style: Theme.of(context).textTheme.titleMedium),
             ],
           ),
         ),
        Expanded(
          child: _zones.isEmpty
              ? const Center(child: Text('Nenhuma zona de entrega cadastrada.'))
              : ListView.separated(
                  itemCount: _zones.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final zone = _zones[index];
                    return ListTile(
                      leading: CircleAvatar(
                          child: Text('${index + 1}'),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('Raio: ${zone.radiusMeters}m ・ Taxa: R\$ ${zone.fee.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                        tooltip: 'Apagar Zona',
                        onPressed: () => _deleteZone(zone),
                      ),
                      onTap: () => _showZoneDialog(zone: zone),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon( // Mudei para ElevatedButton padrão
            onPressed: _showZoneDialog,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Adicionar Nova Zona'),
             style: ElevatedButton.styleFrom(
               minimumSize: const Size(double.infinity, 45),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
} // Fim