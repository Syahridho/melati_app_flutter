class HistoryItem {
  const HistoryItem({
    required this.ticketNumber,
    required this.type,
    required this.title,
    required this.createdAt,
  });

  final String ticketNumber;
  final String type;
  final String title;
  final DateTime createdAt;

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'pengaduan':
        return 'Pengaduan';
      case 'aspirasi':
        return 'Aspirasi';
      case 'permintaan_informasi':
        return 'Permintaan Informasi';
      default:
        return type;
    }
  }

  Map<String, dynamic> toJson() => {
        'ticket_number': ticketNumber,
        'type': type,
        'title': title,
        'created_at': createdAt.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final ticketNumber = (json['ticket_number'] ?? json['ticketNumber'])?.toString() ?? '';
    final type = (json['type'] ?? json['jenis'] ?? '').toString();
    final title = (json['title'] ?? json['judul'] ?? '').toString();
    final createdAtValue = json['created_at'] ?? json['createdAt'];

    return HistoryItem(
      ticketNumber: ticketNumber,
      type: type,
      title: title,
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
