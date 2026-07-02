import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../screens/medicine_detail_screen.dart';
import '../services/app_provider.dart';
import '../theme.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final bool showActions;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.showActions = false,
  });

  Color get _medicineColor {
    try {
      return Color(int.parse(medicine.color.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  String _typeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':
        return '💊';
      case 'syrup':
        return '🧴';
      case 'injection':
        return '💉';
      case 'capsule':
        return '🔴';
      case 'drops':
        return '💧';
      case 'cream':
        return '🧪';
      default:
        return '💊';
    }
  }

  void _showRefillDialog(BuildContext context) {
    final ctrl = TextEditingController(text: '10');
    final formKey = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Refill medicine',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Quantity to add',
              prefixIcon: Icon(Icons.add_box_outlined),
            ),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null) return 'Enter a number';
              if (n <= 0) return 'Must be greater than 0';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final qty = int.parse(ctrl.text.trim());
              context.read<AppProvider>().refillMedicine(medicine, qty);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $qty to ${medicine.name}')),
              );
            },
            child: const Text('Refill'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _medicineColor;

    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineDetailScreen(medicine: medicine),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: medicine.isOutOfStock
                  ? AppTheme.danger.withValues(alpha: 0.5)
                  : medicine.isLowStock
                      ? AppTheme.warning.withValues(alpha: 0.45)
                      : color.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(_typeEmoji(medicine.type),
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              medicine.dosage,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                medicine.type,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StockBadge(medicine: medicine),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${medicine.currentStock} / ${medicine.totalStock} remaining',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  Text(
                    '${(medicine.stockPercentage * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: medicine.stockPercentage,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    medicine.isOutOfStock
                        ? AppTheme.danger
                        : medicine.isLowStock
                            ? AppTheme.warning
                            : color,
                  ),
                  minHeight: 6,
                ),
              ),
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: medicine.isOutOfStock
                            ? null
                            : () => context
                                .read<AppProvider>()
                                .takeMedicine(medicine),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Take Now'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side:
                              const BorderSide(color: AppTheme.primary, width: 1.3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRefillDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Refill'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondary,
                          side: const BorderSide(
                              color: AppTheme.secondary, width: 1.3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final Medicine medicine;
  const _StockBadge({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (medicine.isOutOfStock) {
      color = AppTheme.danger;
      label = 'OUT';
    } else if (medicine.isLowStock) {
      color = AppTheme.warning;
      label = 'LOW';
    } else {
      color = AppTheme.success;
      label = '${medicine.currentStock}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
