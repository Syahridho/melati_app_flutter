enum TicketType {
  pengaduan('pengaduan', 'Pengaduan'),
  aspirasi('aspirasi', 'Aspirasi'),
  permintaanInformasi('permintaan_informasi', 'Permintaan Informasi');

  const TicketType(this.apiValue, this.displayName);

  final String apiValue;
  final String displayName;

  static TicketType fromApiValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'pengaduan':
        return TicketType.pengaduan;
      case 'aspirasi':
        return TicketType.aspirasi;
      case 'permintaan_informasi':
      case 'permintaan informasi':
        return TicketType.permintaanInformasi;
      default:
        return TicketType.pengaduan;
    }
  }

  String get label => displayName;
}

class CreateTicketResult {
  const CreateTicketResult({
    required this.ticketNumber,
    this.accessCode,
  });

  final String ticketNumber;
  final String? accessCode;
}

class TicketResponseItem {
  const TicketResponseItem({
    required this.type,
    required this.message,
    required this.createdAt,
  });

  final String type;
  final String message;
  final DateTime createdAt;

  factory TicketResponseItem.fromJson(Map<String, dynamic> json) {
    final response = json['response'] is Map<String, dynamic>
        ? json['response'] as Map<String, dynamic>
        : json;

    final typeValue = response['type'] ?? response['reply_type'] ?? 'admin';
    final messageValue = response['message'] ?? response['content'] ?? response['reply'];
    final createdAtValue = response['created_at'] ?? response['createdAt'] ?? DateTime.now().toIso8601String();

    return TicketResponseItem(
      type: typeValue.toString(),
      message: messageValue.toString(),
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class TicketDetail {
  const TicketDetail({
    required this.ticketNumber,
    required this.title,
    required this.status,
    required this.responses,
    this.type,
  });

  final String ticketNumber;
  final String title;
  final String status;
  final String? type;
  final List<TicketResponseItem> responses;

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    final payload = _unwrapData(json);
    final responsesSource = payload['responses'];
    
    final ticketNumber =
        (payload['ticket_number'] ?? payload['ticketNumber'] ?? payload['number'])?.toString() ?? '';
    final title = (payload['title'] ?? payload['judul'] ?? '').toString();
    final status = (payload['status'] ?? payload['state'] ?? 'unknown').toString();
    final type = payload['type']?.toString();

    final responses = <TicketResponseItem>[];
    if (responsesSource is List) {
      for (final item in responsesSource) {
        if (item is Map<String, dynamic>) {
          responses.add(TicketResponseItem.fromJson(item));
        } else if (item is Map) {
          responses.add(TicketResponseItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return TicketDetail(
      ticketNumber: ticketNumber,
      title: title,
      status: status,
      responses: responses,
      type: type,
    );
  }

  static Map<String, dynamic> _unwrapData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (json.containsKey('ticket')) {
      final nested = json['ticket'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return json;
  }
}
