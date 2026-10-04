import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/ticket.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/ticket_status_badge.dart';
import '../widgets/app_brand_header.dart';

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key, this.initialTicketNumber, this.autoCheck = false});

  final String? initialTicketNumber;
  final bool autoCheck;

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  final _ticketController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  TicketDetail? _ticketDetail;

  @override
  void initState() {
    super.initState();
    if (widget.initialTicketNumber != null) {
      _ticketController.text = widget.initialTicketNumber!;
    }
    if (widget.autoCheck && widget.initialTicketNumber != null && widget.initialTicketNumber!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkTicket();
        }
      });
    }
  }

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  void _showToast(String title, String message, {bool isError = false}) {
    final toast = isError
        ? ShadToast.destructive(
            title: Text(title),
            description: Text(message),
            duration: const Duration(seconds: 4),
          )
        : ShadToast(
            title: Text(title),
            description: Text(message),
            duration: const Duration(seconds: 4),
          );
    ShadSonner.of(context).show(toast);
  }

  Future<void> _checkTicket() async {
    final ticketNumber = _ticketController.text.trim();
    if (ticketNumber.isEmpty) {
      _showToast('Nomor tiket', 'Masukkan nomor tiket terlebih dahulu.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final detail = await ApiService.instance.fetchTicket(ticketNumber);
      if (!mounted) {
        return;
      }
      setState(() {
        _ticketDetail = detail;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ticketDetail = null;
      });
      _showToast('Gagal mengecek', error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ticketDetail = null;
      });
      _showToast('Gagal mengecek', 'Tidak dapat terhubung ke server.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketDetail = _ticketDetail;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBrandHeader(title: 'Cek Laporan'),
                const SizedBox(height: 16),
                ShadInputFormField(
                  controller: _ticketController,
                  label: const Text('Nomor tiket'),
                  placeholder: const Text('L/2026/0001'),
                  keyboardType: TextInputType.text,
                  onSubmitted: (_) => _checkTicket(),
                  validator: (value) {
                    if (value.trim().isEmpty) {
                      return 'Nomor tiket wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: _isLoading ? null : _checkTicket,
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Mengcek...'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 16),
                              SizedBox(width: 8),
                              Text('Cek'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                if (ticketDetail != null) ...[
                  ShadCard(
                    title: Text(ticketDetail.title.isNotEmpty ? ticketDetail.title : 'Judul tiket'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ticketDetail.ticketNumber,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TicketStatusBadge(status: ticketDetail.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nomor tiket: ${ticketDetail.ticketNumber}',
                          style: TextStyle(color: ShadTheme.of(context).colorScheme.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Balasan admin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (ticketDetail.responses.isEmpty)
                    const EmptyState(
                      title: 'Belum ada balasan',
                      description: 'Laporan Anda masih menunggu tanggapan dari admin.',
                    )
                  else
                    ...ticketDetail.responses.map((response) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ShadCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      response.type,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    response.createdAt.toLocal().toString().split(' ').first,
                                    style: TextStyle(
                                      color: ShadTheme.of(context).colorScheme.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(response.message),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
