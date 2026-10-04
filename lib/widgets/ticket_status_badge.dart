import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TicketStatusBadge extends StatelessWidget {
  const TicketStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim();
    final variant = switch (normalized.toLowerCase()) {
      'selesai' => ShadBadgeVariant.primary,
      'tertutup' => ShadBadgeVariant.primary,
      'dalam proses' || 'diproses' || 'proses' => ShadBadgeVariant.secondary,
      'menunggu' => ShadBadgeVariant.outline,
      _ => ShadBadgeVariant.outline,
    };

    return switch (variant) {
      ShadBadgeVariant.primary => ShadBadge(child: Text(normalized.isEmpty ? 'Status' : normalized)),
      ShadBadgeVariant.secondary => ShadBadge.secondary(child: Text(normalized.isEmpty ? 'Status' : normalized)),
      ShadBadgeVariant.outline => ShadBadge.outline(child: Text(normalized.isEmpty ? 'Status' : normalized)),
      ShadBadgeVariant.destructive => ShadBadge.destructive(child: Text(normalized.isEmpty ? 'Status' : normalized)),
    };
  }
}
