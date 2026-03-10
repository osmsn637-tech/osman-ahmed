import 'package:flutter/material.dart';

class ScanBox extends StatelessWidget {
  const ScanBox({super.key, required this.label, this.subLabel, this.highlight = false, this.onTap});

  final String label;
  final String? subLabel;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.blue.shade50 : Colors.grey.shade100;
    final border = highlight ? Colors.blue.shade300 : Colors.grey.shade400;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: highlight ? Colors.blue.shade800 : Colors.grey.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    if (subLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(subLabel!, style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
