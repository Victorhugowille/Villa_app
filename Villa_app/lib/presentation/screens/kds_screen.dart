import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/app_data.dart' as app_data;
import '../providers/kds_provider.dart';
import '../providers/printer_provider.dart';
// O import do 'side_menu.dart' não é mais necessário aqui
// import 'package:villabistromobile/widgets/side_menu.dart';

class KdsScreen extends StatefulWidget {
  const KdsScreen({super.key});

  @override
  State<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends State<KdsScreen> {
  late KdsProvider _kdsProvider;

  @override
  void initState() {
    super.initState();
    _kdsProvider = Provider.of<KdsProvider>(context, listen: false);
    _kdsProvider.listenToOrders();
  }

  @override
  void dispose() {
    _kdsProvider.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final kdsProvider = context.watch<KdsProvider>();

    // =================== LAYOUT PARA DESKTOP ===================
    if (isDesktop) {
      // Lista de booleanos para o ToggleButtons
      final isSelected = [
        kdsProvider.filter == KdsFilter.all,
        kdsProvider.filter == KdsFilter.table,
        kdsProvider.filter == KdsFilter.delivery,
      ];

      return Stack(
        // 1. O Stack permite sobrepor widgets
        children: [
          // 2. O conteúdo principal (as colunas)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: OrderColumn(
                  key: const ValueKey('production_column_desktop'),
                  title: 'Em produção',
                  color: Colors.orange.shade700,
                  orders: kdsProvider.productionOrders,
                ),
              ),
              Expanded(
                child: OrderColumn(
                  key: const ValueKey('ready_column_desktop'),
                  title: 'Prontos',
                  color: Colors.green.shade700,
                  orders: kdsProvider.readyOrders,
                ),
              ),
            ],
          ),
          // 3. O widget de filtro flutuante
          Positioned(
            bottom: 16,
            right: 16,
            child: Material(
              elevation: 6.0,
              borderRadius: BorderRadius.circular(8.0),
              clipBehavior: Clip.antiAlias, // Para o 'splash' do botão
              child: ToggleButtons(
                isSelected: isSelected,
                onPressed: (int index) {
                  KdsFilter newFilter;
                  switch (index) {
                    case 0:
                      newFilter = KdsFilter.all;
                      break;
                    case 1:
                      newFilter = KdsFilter.table;
                      break;
                    case 2:
                      newFilter = KdsFilter.delivery;
                      break;
                    default:
                      newFilter = KdsFilter.all;
                  }
                  // Usar 'read' para chamar a função sem reconstruir o widget
                  context.read<KdsProvider>().setFilter(newFilter);
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Tooltip(
                      message: 'Todos os Pedidos',
                      child: Icon(Icons.apps),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Tooltip(
                      message: 'Apenas Mesas',
                      child: Icon(Icons.deck_outlined),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Tooltip(
                      message: 'Apenas Delivery',
                      child: Icon(Icons.delivery_dining_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return DefaultTabController(
      length: 2, 
      child: Column(
        children: [
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: TabBar(
              indicatorColor: Theme.of(context).indicatorColor,
              labelColor: Theme.of(context).textTheme.titleMedium?.color, 
              unselectedLabelColor: Theme.of(context).textTheme.titleMedium?.color?.withOpacity(0.7),
              tabs: [
                Tab(text: 'EM PRODUÇÃO (${kdsProvider.productionOrders.length})'),
                Tab(text: 'PRONTOS (${kdsProvider.readyOrders.length})'),
              ],
            ),
          ),
          Expanded(
            child: kdsProvider.isLoading &&
                    kdsProvider.productionOrders.isEmpty &&
                    kdsProvider.readyOrders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      OrderColumn(
                        key: const ValueKey('production_column_mobile'),
                        title: 'Em produção',
                        orders: kdsProvider.productionOrders,
                        showTitle: false, // O título já está na aba
                      ),
                      OrderColumn(
                        key: const ValueKey('ready_column_mobile'),
                        title: 'Prontos',
                        orders: kdsProvider.readyOrders,
                        showTitle: false, // O título já está na aba
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderColumn extends StatelessWidget {
  final String title;
  final Color? color;
  final List<app_data.Order> orders;
  final bool showTitle;

  const OrderColumn({
    super.key,
    required this.title,
    this.color,
    required this.orders,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget content = orders.isEmpty
        ? const Center(child: Text('Nenhum pedido no momento.'))
        : ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return OrderCard(
                  key: ValueKey(orders[index].id), order: orders[index]);
            },
          );

    if (!isDesktop) {
      return content; // No celular, retorna apenas a lista rolável para o TabBarView
    }

    // No desktop, retorna o design de coluna com bordas e título
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          if (showTitle) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${title.toUpperCase()} (${orders.length})',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
            const Divider(height: 1, thickness: 1),
          ],
          Expanded(child: content),
        ],
      ),
    );
  }
}

// O widget OrderCard permanece o mesmo da versão anterior.
class OrderCard extends StatefulWidget {
  final app_data.Order order;
  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  Timer? _timer;
  late int _minutesAgo;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _minutesAgo =
            DateTime.now().difference(widget.order.timestamp).inMinutes;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getTimeColor(int minutes) {
    if (minutes > 10) return Colors.red.shade700;
    if (minutes > 5) return Colors.orange.shade800;
    return Colors.grey.shade600;
  }

  Future<void> _launchNavigationApps(String? googleMapsUrl) async {
    if (googleMapsUrl == null || googleMapsUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link de localização não disponível.')),
      );
      return;
    }

    final RegExp regExp = RegExp(r"(-?\d+\.\d+),(-?\d+\.\d+)");
    final match = regExp.firstMatch(googleMapsUrl);

    if (match == null || match.groupCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordenadas inválidas no link.')),
      );
      return;
    }

    final lat = match.group(1);
    final lon = match.group(2);

    final wazeUri = Uri.parse('waze://?ll=$lat,$lon&navigate=yes');
    final googleUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');

    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri);
    } else if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir nenhum app de mapa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kdsProvider = Provider.of<KdsProvider>(context, listen: false);
    final printerProvider =
        Provider.of<PrinterProvider>(context, listen: false);
    final isDelivery = widget.order.type == 'delivery';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDelivery ? Colors.blue.shade300 : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, printerProvider),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDelivery && widget.order.deliveryInfo != null)
                  _buildDeliveryInfo(widget.order.deliveryInfo!),
                ...widget.order.items
                    .map((item) => _buildItemRow(context, item)),
                if (widget.order.observacao != null &&
                    widget.order.observacao!.isNotEmpty)
                  _buildObservationSection(widget.order.observacao!),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        kdsProvider.advanceOrder(context, widget.order),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: widget.order.status == 'production' ||
                              widget.order.status == 'awaiting_print'
                          ? Colors.blueAccent
                          : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.order.status == 'ready' && !isDelivery
                        ? 'Receber Pagamento'
                        : 'Avançar Pedido'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(
      BuildContext context, PrinterProvider printerProvider) {
    final isDelivery = widget.order.type == 'delivery';

    return Container(
      color: isDelivery
          ? Colors.blue.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDelivery
                      ? Icons.delivery_dining_outlined
                      : Icons.deck_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isDelivery
                        ? 'DELIVERY #${widget.order.id}'
                        : 'MESA ${widget.order.tableNumber}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                'há $_minutesAgo min',
                style: TextStyle(
                    color: _getTimeColor(_minutesAgo),
                    fontWeight: FontWeight.bold),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'reprint') {
                    printerProvider.reprintOrder(widget.order);
                  } else if (value == 'location') {
                    _launchNavigationApps(
                        widget.order.deliveryInfo?.locationLink);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'reprint',
                    child: ListTile(
                      leading: Icon(Icons.print_outlined),
                      title: Text('Reimprimir Pedido'),
                    ),
                  ),
                  if (isDelivery &&
                      widget.order.deliveryInfo?.locationLink != null)
                    const PopupMenuItem<String>(
                      value: 'location',
                      child: ListTile(
                        leading: Icon(Icons.map_outlined),
                        title: Text('Ver Localização'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(app_data.DeliveryInfo info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.person_outline, info.nomeCliente),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.phone_outlined, info.telefoneCliente),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.home_outlined, info.enderecoEntrega),
          const SizedBox(height: 8),
          if (info.locationLink != null && info.locationLink!.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Navegar com Waze'),
                    onPressed: () => _launchNavigationApps(info.locationLink),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'Copiar link',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: info.locationLink!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copiado!')),
                    );
                  },
                ),
              ],
            ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildItemRow(BuildContext context, app_data.CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 16),
              children: [
                TextSpan(
                  text: '${item.quantity}x ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: item.product.name),
              ],
            ),
          ),
          if (item.selectedAdicionais.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.selectedAdicionais
                    .map((adicional) => Text(
                          '+ ${adicional.quantity}x ${adicional.adicional.name}',
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 13),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildObservationSection(String observation) {
    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade700, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sticky_note_2_outlined,
              color: Colors.yellow.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              observation,
              style: TextStyle(
                  color: Colors.yellow.shade900, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}