import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/company_provider.dart';

class DestaquesSiteScreen extends StatefulWidget {
  const DestaquesSiteScreen({super.key});

  @override
  State<DestaquesSiteScreen> createState() => _DestaquesSiteScreenState();
}

class _DestaquesSiteScreenState extends State<DestaquesSiteScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<int, DestaqueSite> _destaquesMap = {};

  @override
  void initState() {
    super.initState();
    _fetchDestaques();
  }

  Future<void> _fetchDestaques() async {
    setState(() => _isLoading = true);
    try {
      final companyId =
          Provider.of<CompanyProvider>(context, listen: false).companyId;
      if (companyId == null) {
        throw 'ID da empresa não encontrado.';
      }

      final response = await _supabase
          .from('destaque_site')
          .select()
          .eq('company_id', companyId);

      final destaques =
          response.map((item) => DestaqueSite.fromJson(item)).toList();

      _destaquesMap.clear();
      for (var destaque in destaques) {
        _destaquesMap[destaque.slotNumber] = destaque;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar destaques: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // FUNÇÃO DE UPLOAD CORRIGIDA
  Future<void> _uploadImage(int slotNumber) async {
    // Agora esta linha funciona corretamente por causa da correção no provider
    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
    if (companyId == null) return;

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'destaque_${slotNumber}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$companyId/destaques/$fileName';

      // ### CORREÇÃO CRÍTICA AQUI ###
      // Lógica para remover a imagem antiga do storage
      if (_destaquesMap.containsKey(slotNumber)) {
        final oldUrl = _destaquesMap[slotNumber]!.imageUrl;
        final oldUri = Uri.parse(oldUrl);
        // O caminho correto é tudo que vem DEPOIS do nome do bucket na URL
        final oldPath = oldUri.pathSegments.sublist(oldUri.pathSegments.indexOf('product_images') + 1).join('/');
        await _supabase.storage.from('product_images').remove([oldPath]);
      }

      await _supabase.storage
          .from('product_images')
          .uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: 'image/$fileExt'));

      final imageUrl = _supabase.storage.from('product_images').getPublicUrl(filePath);

      await _supabase.from('destaque_site').upsert({
        'company_id': companyId,
        'slot_number': slotNumber,
        'image_url': imageUrl,
      }, onConflict: 'company_id, slot_number');
      
      await _fetchDestaques();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro no upload: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // FUNÇÃO DE DELETAR CORRIGIDA
  Future<void> _deleteImage(int slotNumber) async {
    final destaque = _destaquesMap[slotNumber];
    if (destaque == null) return;

    setState(() => _isLoading = true);
    try {
      // Deleta a referência no banco de dados primeiro
      await _supabase.from('destaque_site').delete().eq('id', destaque.id);

      // ### CORREÇÃO CRÍTICA AQUI ###
      // Lógica para remover o arquivo do storage
      final oldUrl = destaque.imageUrl;
      final oldUri = Uri.parse(oldUrl);
      final oldPath = oldUri.pathSegments.sublist(oldUri.pathSegments.indexOf('product_images') + 1).join('/');
      await _supabase.storage.from('product_images').remove([oldPath]);

      await _fetchDestaques();
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao deletar imagem: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final images = _destaquesMap.values.map((d) => d.imageUrl).toList();
    images.sort((a, b) {
      final numA = _destaquesMap.entries.firstWhere((e) => e.value.imageUrl == a, orElse: () => _destaquesMap.entries.first).key;
      final numB = _destaquesMap.entries.firstWhere((e) => e.value.imageUrl == b, orElse: () => _destaquesMap.entries.first).key;
      return numA.compareTo(numB);
    });

    return Scaffold(
      appBar: AppBar(
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
            onRefresh: _fetchDestaques,
            child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text('Pré-visualização do Carrossel', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (images.isNotEmpty)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 200.0,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 8),
                        enlargeCenterPage: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 0.8,
                      ),
                      items: images.map((imageUrl) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    return progress == null ? child : const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stack) => const Icon(Icons.error, color: Colors.white70),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Nenhuma imagem de destaque adicionada.', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Text('Gerenciar Imagens', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final slotNumber = index + 1;
                      final destaque = _destaquesMap[slotNumber];
                      return _buildSlotEditor(slotNumber, destaque);
                    },
                  ),
                ],
              ),
          ),
    );
  }

  Widget _buildSlotEditor(int slotNumber, DestaqueSite? destaque) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onTap: () => _uploadImage(slotNumber),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
            image: destaque != null
                ? DecorationImage(
                    image: NetworkImage(destaque.imageUrl),
                    fit: BoxFit.cover,
                    onError: (error, stack) {},
                  )
                : null,
          ),
          child: Stack(
            children: [
              if (destaque == null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo, size: 40, color: Colors.white70),
                      const SizedBox(height: 8),
                      Text('Destaque $slotNumber', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              if (destaque != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteImage(slotNumber),
                      tooltip: 'Remover Imagem',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}