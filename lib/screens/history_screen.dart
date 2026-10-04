import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/history_item.dart';
import '../services/history_storage.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_brand_header.dart';
import 'check_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.refreshTrigger});

  final ValueNotifier<int>? refreshTrigger;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _items = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger?.addListener(_loadHistory);
    _loadHistory();
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await HistoryStorage.instance.loadHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteHistory(HistoryItem item) async {
    if (!mounted) {
      return;
    }

    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return ShadDialog(
          title: const Text('Hapus riwayat?'),
          description: const Text('Hanya dihapus dari perangkat ini dan laporan di server tidak ikut terhapus.'),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ShadButton.destructive(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await HistoryStorage.instance.removeItem(item.ticketNumber);
    if (!mounted) {
      return;
    }
    await _loadHistory();
    if (!mounted) {
      return;
    }
    ShadSonner.of(context).show(
      ShadToast(
        title: const Text('Riwayat dihapus'),
        description: const Text('Item telah dihapus dari perangkat ini.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AppBrandHeader(title: 'Riwayat Laporan'),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const EmptyState(
                          title: 'Belum ada riwayat laporan',
                          description: 'Laporan yang Anda kirim akan muncul di sini.',
                          icon: Icons.history,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                      final item = _items[index];
                      return ShadCard(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckScreen(
                                  initialTicketNumber: item.ticketNumber,
                                  autoCheck: true,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.ticketNumber,
                                        style: TextStyle(
                                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          ShadBadge.outline(
                                            child: Text(item.typeLabel),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.createdAt.toLocal().toString().split(' ').first,
                                            style: TextStyle(
                                              color: ShadTheme.of(context).colorScheme.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ShadButton.destructive(
                                  onPressed: () => _deleteHistory(item),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
