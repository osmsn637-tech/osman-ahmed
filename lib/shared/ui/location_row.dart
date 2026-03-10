import 'package:flutter/material.dart';
import 'status_badge.dart';

class LocationRow extends StatelessWidget {
  const LocationRow({
    super.key,
    required this.code,
    required this.typeLabel,
    required this.quantity,
    this.trailing,
    this.isShelfOverride,
  });

  final String code;
  final String typeLabel;
  final String quantity;
  final Widget? trailing;
  final bool? isShelfOverride;

  @override
  Widget build(BuildContext context) {
    final isShelf =
        isShelfOverride ?? typeLabel.toLowerCase().contains('shelf');
    final badgeColor = isShelf ? Colors.blue.shade700 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          StatusBadge(label: typeLabel, color: badgeColor),
          const SizedBox(width: 10),
          Text(
            quantity,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
