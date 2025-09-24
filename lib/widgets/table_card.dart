import 'package:flutter/material.dart';

class TableCard extends StatelessWidget {
  final int tableNumber;
  final bool isOccupied;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.tableNumber,
    required this.isOccupied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor = isOccupied ? Colors.orangeAccent : theme.primaryColor;
    final IconData statusIcon = isOccupied ? Icons.people_alt : Icons.table_bar;

    return Card(
      color: theme.colorScheme.onBackground.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 40),
              const SizedBox(width: 20),
              Text(
                'Mesa $tableNumber',
                style: TextStyle(
                  color: theme.colorScheme.onBackground,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isOccupied)
                const Text(
                  'Ocupada',
                  style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onBackground.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}