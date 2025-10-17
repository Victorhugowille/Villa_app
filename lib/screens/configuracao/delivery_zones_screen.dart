// lib/screens/configuracao/delivery_zones_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

// Modelo da Zona de Entrega (sem alterações)
class DeliveryZone {
  final String id;
  final String name;
  final int radiusMeters;
  final double fee;
  DeliveryZone({required this.id, required this.name, required this.radiusMeters, required this.fee});
  factory DeliveryZone.fromMap(Map<String, dynamic> map) {
    return DeliveryZone(
      id: map['id'],
      name: map['name'],
      radiusMeters: (map['radius_meters'] as num).toInt(),
      fee: (map['fee'] as num).toDouble(),
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _company = context.read<CompanyProvider>().currentCompany;
    if (_company == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    if (_company!.latitude != null && _company!.longitude != null) {
      _savedCompanyLocation = LatLng(_company!.latitude!, _company!.longitude!);
    }

    await _fetchZones();
    setState(() => _isLoading = false);
  }
  
  Future<void> _fetchZones() async {
     try {
      final response = await Supabase.instance.client
        .from('delivery_zones').select().eq('company_id', _company!.id).order('radius_meters', ascending: true);
      _zones = response.map((map) => DeliveryZone.fromMap(map)).toList();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar zonas: $e')));
    }
  }

  Future<void> _saveSelectedLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toque no mapa para escolher uma localização antes de salvar.')));
      return;
    }

    try {
      await Supabase.instance.client
        .from('companies')
        .update({'latitude': _selectedLocation!.latitude, 'longitude': _selectedLocation!.longitude})
        .eq('id', _company!.id);
      
      await context.read<CompanyProvider>().fetchCompanyForCurrentUser();
      
      setState(() {
        _savedCompanyLocation = _selectedLocation;
        _selectedLocation = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Localização do restaurante salva com sucesso!')));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar localização: $e')));
    }
  }

  Future<void> _centerOnMyLocation() async {
     try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Serviços de localização estão desativados.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permissão de localização negada.';
      }
      if (permission == LocationPermission.deniedForever) throw 'Permissão de localização negada permanentemente.';

      final position = await Geolocator.getCurrentPosition();
      final myLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(myLocation, 15.0);

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar localização: $e')));
    }
  }
  
  void _showZoneDialog({DeliveryZone? zone}) {
    final nameController = TextEditingController(text: zone?.name);
    final radiusController = TextEditingController(text: zone?.radiusMeters.toString() ?? '');
    
    // CORREÇÃO AQUI: 'thousandSeparator' em vez de 'thousandsSeparator'
    final feeController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', 
      decimalSeparator: ',', 
      thousandSeparator: '.', // <<<<<<<<<< CORRIGIDO
      initialValue: zone?.fee ?? 0.0
    );

    final formKey = GlobalKey<FormState>();

    void updatePreviewCircle() {
      final radius = int.tryParse(radiusController.text) ?? 0;
      if (_savedCompanyLocation != null && radius > 0) {
        setState(() {
          _previewCircle = CircleMarker(
            point: _savedCompanyLocation!,
            radius: radius.toDouble(),
            useRadiusInMeter: true,
            color: Colors.orange.withOpacity(0.3),
            borderColor: Colors.orange,
            borderStrokeWidth: 2,
          );
        });
      } else {
        setState(() => _previewCircle = null);
      }
    }
    radiusController.addListener(updatePreviewCircle);
    updatePreviewCircle();

    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: Text(zone == null ? 'Adicionar Nova Zona' : 'Editar Zona'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da Zona (Ex: Centro)'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                TextFormField(controller: radiusController, decoration: const InputDecoration(labelText: 'Raio (em metros)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                TextFormField(controller: feeController, decoration: const InputDecoration(labelText: 'Taxa de Entrega (R\$)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final radius = int.tryParse(radiusController.text);
                final fee = feeController.numberValue;

                if (radius == null || radius <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Raio inválido. Insira um número maior que zero.')));
                  return;
                }
                
                final data = {
                  'company_id': _company!.id,
                  'name': nameController.text,
                  'radius_meters': radius,
                  'fee': fee,
                };

                try {
                  if (zone == null) {
                    await Supabase.instance.client.from('delivery_zones').insert(data);
                  } else {
                    await Supabase.instance.client.from('delivery_zones').update(data).eq('id', zone.id);
                  }
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                   if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar zona: $e')));
                }
              }, 
              child: const Text('Salvar'),
            ),
          ],
        );
      }
    ).whenComplete(() {
      setState(() => _previewCircle = null);
      radiusController.removeListener(updatePreviewCircle);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_company == null) return const Center(child: Text('Empresa não encontrada.'));

    List<Marker> markers = [];
    List<CircleMarker> circles = [];

    if (_savedCompanyLocation != null) {
      markers.add(Marker(
        point: _savedCompanyLocation!,
        child: Icon(Icons.store, color: Theme.of(context).primaryColor, size: 40),
      ));
      circles = _zones.map((zone) => CircleMarker(
        point: _savedCompanyLocation!,
        radius: zone.radiusMeters.toDouble(),
        useRadiusInMeter: true,
        color: Colors.blue.withOpacity(0.2),
        borderColor: Colors.blue,
        borderStrokeWidth: 2,
      )).toList();
    }
    if (_selectedLocation != null) {
      markers.add(Marker(
        point: _selectedLocation!,
        child: const Icon(Icons.location_on, color: Colors.green, size: 40),
      ));
    }
    if (_previewCircle != null) {
      circles.add(_previewCircle!);
    }
    
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _savedCompanyLocation ?? const LatLng(-25.18, -54.06),
              initialZoom: 14,
              onTap: (_, pos) => setState(() => _selectedLocation = pos),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.villabistromobile.app',
              ),
              CircleLayer(circles: circles),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildLocationPanel(),
              const Divider(height: 1),
              Expanded(child: _buildZonesPanel()),
            ],
          )
        )
      ],
    );
  }

  Widget _buildLocationPanel() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _selectedLocation == null 
              ? 'Toque no mapa para definir a localização do restaurante'
              : 'Nova localização selecionada. Clique em salvar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _centerOnMyLocation,
                tooltip: 'Buscar minha localização atual',
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedLocation == null ? null : _saveSelectedLocation, 
                  icon: const Icon(Icons.save), 
                  label: const Text('Salvar Localização do Restaurante'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildZonesPanel() {
    if (_savedCompanyLocation == null) {
      return const Center(child: Text('Salve a localização do restaurante para gerenciar as zonas de entrega.'));
    }
    return Column(
      children: [
        Expanded(
          child: _zones.isEmpty
          ? const Center(child: Text('Nenhuma zona de entrega cadastrada.'))
          : ListView.builder(
            itemCount: _zones.length,
            itemBuilder: (context, index) {
              final zone = _zones[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(zone.name),
                subtitle: Text('Raio: ${zone.radiusMeters}m - Taxa: R\$ ${zone.fee.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                     await Supabase.instance.client.from('delivery_zones').delete().eq('id', zone.id);
                     _loadData();
                  },
                ),
                onTap: () => _showZoneDialog(zone: zone),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton.extended(
            onPressed: _showZoneDialog, 
            label: const Text('Adicionar Nova Zona'),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}