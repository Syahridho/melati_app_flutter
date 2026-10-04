import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/history_item.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../services/history_storage.dart';
import '../widgets/app_brand_header.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.onSavedToHistory});

  final VoidCallback? onSavedToHistory;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tabsController = ShadTabsController<TicketType>(
    value: TicketType.pengaduan,
  );
  final List<TicketAttachment> _attachments = [];

  DateTime? _incidentDate;
  bool _isSubmitting = false;
  static const int _maxAttachmentCount = 3;
  static const int _maxAttachmentSize = 2 * 1024 * 1024;

  TicketType get _selectedType => _tabsController.selected;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _tabsController.dispose();
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

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final email = value.trim();
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validateWhatsApp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim().length < 8 ? 'Nomor WhatsApp minimal 8 digit' : null;
  }

  Future<void> _pickAttachments() async {
    final remaining = _maxAttachmentCount - _attachments.length;
    if (remaining <= 0) {
      _showToast(
        'Lampiran penuh',
        'Maksimal $_maxAttachmentCount file.',
        isError: true,
      );
      return;
    }

    late final List<PlatformFile> result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );
    } on Exception catch (error) {
      if (mounted) {
        _showToast('Gagal memilih file', error.toString(), isError: true);
      }
      return;
    }
    if (result.isEmpty || !mounted) {
      return;
    }

    if (result.length > remaining) {
      _showToast(
        'Terlalu banyak file',
        'Anda hanya dapat menambahkan $remaining file lagi.',
        isError: true,
      );
      return;
    }

    final invalidFiles = <String>[];
    final acceptedFiles = <TicketAttachment>[];
    for (final file in result) {
      final extension = file.extension?.toLowerCase();
      if (!const {'jpg', 'jpeg', 'png', 'pdf'}.contains(extension)) {
        invalidFiles.add('${file.name}: format tidak didukung');
      } else {
        final size = file.lengthSync() ?? await file.length();
        if (!mounted) {
          return;
        }
        if (size == null) {
          invalidFiles.add('${file.name}: ukuran file tidak dapat dibaca');
        } else if (size > _maxAttachmentSize) {
          invalidFiles.add('${file.name}: ukuran melebihi 2 MB');
        } else {
          late final Uint8List bytes;
          try {
            bytes = await file.readAsBytes();
          } on Exception catch (error) {
            invalidFiles.add('${file.name}: tidak dapat dibaca ($error)');
            continue;
          }
          if (!mounted) {
            return;
          }
          if (bytes.length > _maxAttachmentSize) {
            invalidFiles.add('${file.name}: ukuran melebihi 2 MB');
          } else {
            acceptedFiles.add(TicketAttachment(name: file.name, bytes: bytes));
          }
        }
      }
    }

    setState(() => _attachments.addAll(acceptedFiles));
    if (invalidFiles.isNotEmpty) {
      _showToast(
        'File tidak ditambahkan',
        invalidFiles.join('. '),
        isError: true,
      );
    }
  }

  void _removeAttachment(TicketAttachment file) {
    setState(() => _attachments.remove(file));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == TicketType.pengaduan && _incidentDate == null) {
      _showToast(
        'Tanggal kejadian',
        'Pilih tanggal kejadian terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final submittedType = _selectedType;
      final submittedTitle = _titleController.text.trim();
      final result = await ApiService.instance.createTicket(
        type: submittedType,
        name: _nameController.text,
        email: _emailController.text,
        whatsapp: _whatsappController.text,
        incidentDate: _incidentDate,
        title: _titleController.text,
        content: _contentController.text,
        attachments: _attachments,
      );

      final item = HistoryItem(
        ticketNumber: result.ticketNumber,
        type: submittedType.apiValue,
        title: submittedTitle,
        createdAt: DateTime.now(),
      );
      if (mounted) {
        _clearForm();
      }
      await HistoryStorage.instance.addItem(item);
      widget.onSavedToHistory?.call();

      if (!mounted) {
        return;
      }

      final accepted = await showShadDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return ShadDialog(
            title: const Text('Laporan terkirim'),
            description: const Text(
              'Simpan nomor tiket Anda untuk mengecek status.',
            ),
            actions: [
              ShadButton.outline(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: result.ticketNumber),
                  );
                  if (!dialogContext.mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop(true);
                  if (mounted) {
                    _showToast('Nomor tiket', 'Nomor tiket berhasil disalin.');
                  }
                },
                child: const Text('Salin tiket'),
              ),
              ShadButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tutup'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nomor tiket'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ShadTheme.of(dialogContext).colorScheme.muted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      result.ticketNumber,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (accepted == true) {
        _showToast('Berhasil', 'Laporan berhasil dikirim.');
      }
    } on ApiException catch (error) {
      _showToast('Gagal mengirim', error.message, isError: true);
    } catch (_) {
      _showToast(
        'Gagal mengirim',
        'Terjadi kesalahan yang tidak terduga.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _whatsappController.clear();
      _titleController.clear();
      _contentController.clear();
      _attachments.clear();
      _incidentDate = null;
      _tabsController.select(TicketType.pengaduan);
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final titleLabel = switch (_selectedType) {
      TicketType.pengaduan => 'Judul pengaduan',
      TicketType.aspirasi => 'Judul aspirasi',
      TicketType.permintaanInformasi => 'Judul permintaan informasi',
    };
    final contentLabel = switch (_selectedType) {
      TicketType.pengaduan => 'Isi pengaduan',
      TicketType.aspirasi => 'Isi aspirasi',
      TicketType.permintaanInformasi => 'Isi permintaan informasi',
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ShadForm(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppBrandHeader(title: 'Beri Laporan'),
                  ShadTabs<TicketType>(
                    controller: _tabsController,
                    tabs: TicketType.values
                        .map(
                          (type) => ShadTab<TicketType>(
                            value: type,
                            content: const SizedBox.shrink(),
                            child: Text(
                              type == TicketType.permintaanInformasi
                                  ? 'Informasi'
                                  : type.displayName,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  ShadInputFormField(
                    controller: _nameController,
                    label: const Text('Nama'),
                    placeholder: const Text('Nama Anda (opsional)'),
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 12),
                  ShadInputFormField(
                    controller: _emailController,
                    label: const Text('Email'),
                    placeholder: const Text('nama@email.com'),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),
                  ShadInputFormField(
                    controller: _whatsappController,
                    label: const Text('WhatsApp'),
                    placeholder: const Text('08xxxxxxxxxx'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateWhatsApp,
                  ),
                  if (_selectedType == TicketType.pengaduan) ...[
                    const SizedBox(height: 12),
                    ShadDatePickerFormField(
                      label: const Text('Tanggal kejadian'),
                      placeholder: const Text('Pilih tanggal'),
                      initialValue: _incidentDate,
                      onChanged: (value) {
                        setState(() {
                          _incidentDate = value;
                        });
                      },
                      formatDate: (date) =>
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                    ),
                  ],
                  const SizedBox(height: 12),
                  ShadInputFormField(
                    controller: _titleController,
                    label: Text(titleLabel),
                    placeholder: Text(titleLabel),
                    validator: (value) {
                      if (value.trim().isEmpty) {
                        return 'Judul wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ShadTextareaFormField(
                    controller: _contentController,
                    label: Text(contentLabel),
                    placeholder: Text('Tulis $contentLabel secara jelas...'),
                    minHeight: 120,
                    validator: (value) {
                      if (value.trim().isEmpty) {
                        return 'Isi laporan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lampiran (opsional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maksimal 3 file • JPG, PNG, PDF • Maks. 2 MB per file',
                    style: TextStyle(
                      fontSize: 12,
                      color: ShadTheme.of(context).colorScheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_attachments.isNotEmpty)
                    ..._attachments.map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ShadCard(
                          child: Row(
                            children: [
                              Icon(
                                file.name.toLowerCase().endsWith('.pdf')
                                    ? Icons.picture_as_pdf_outlined
                                    : Icons.image_outlined,
                                color: const Color(0xFF005FB6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('${(file.bytes.length / 1024).ceil()} KB'),
                              IconButton(
                                tooltip: 'Hapus ${file.name}',
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _removeAttachment(file),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton.outline(
                      onPressed: _isSubmitting ? null : _pickAttachments,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.attach_file, size: 16),
                          SizedBox(width: 8),
                          Text('Pilih file'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Mengirim...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 16),
                                SizedBox(width: 8),
                                Text('Kirim Laporan'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
