import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/ticket.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TicketAttachment {
  const TicketAttachment({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();

  Map<String, String> _headers() => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    AppConfig.apiKeyHeader: AppConfig.apiKey,
  };

  Future<Map<String, dynamic>> _parseJson(http.Response response) async {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'data': data};
    } on FormatException {
      return {};
    }
  }

  void _throwForStatus(http.Response response, Map<String, dynamic> body) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final errors = body['errors'];
    if (response.statusCode == 422 && errors is Map) {
      final messages = <String>[];
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List) {
          messages.addAll(value.map((item) => item.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
      }
      if (messages.isNotEmpty) {
        throw ApiException(messages.first);
      }
    }

    switch (response.statusCode) {
      case 401:
      case 403:
        throw const ApiException('API key tidak valid');
      case 404:
        throw const ApiException('Nomor tiket tidak ditemukan');
      case 429:
        throw const ApiException(
          'Terlalu banyak permintaan, coba lagi sebentar',
        );
      default:
        final message = body['message']?.toString();
        if (message != null && message.isNotEmpty) {
          throw ApiException(message);
        }
        throw const ApiException('Tidak dapat terhubung ke server');
    }
  }

  String _encodeTicketPath(String ticketNumber) {
    final segments = ticketNumber.split('/');
    return segments.map((segment) => Uri.encodeComponent(segment)).join('/');
  }

  dynamic _coalesceData(Map<String, dynamic> body) {
    if (body['data'] != null) {
      return body['data'];
    }
    if (body['result'] != null) {
      return body['result'];
    }
    if (body['ticket'] != null) {
      return body['ticket'];
    }
    return body;
  }

  Future<CreateTicketResult> createTicket({
    required TicketType type,
    String? name,
    String? email,
    String? whatsapp,
    DateTime? incidentDate,
    required String title,
    required String content,
    List<TicketAttachment> attachments = const [],
  }) async {
    // Laravel hanya menerima angka untuk reporter_wa
    final wa = whatsapp?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    // Tanggal kejadian tidak ada di validasi Laravel, jadi digabung ke isi laporan
    var finalContent = content.trim();
    if (type == TicketType.pengaduan && incidentDate != null) {
      final tgl = incidentDate.toIso8601String().split('T').first;
      finalContent = 'Tanggal kejadian: $tgl\n\n$finalContent';
    }

    final payload = <String, dynamic>{
      'channel_id': AppConfig.channelId,
      'classification': type.apiValue,
      'title': title.trim(),
      'content': finalContent,
      'source_app': 'flutter',
      if (name != null && name.trim().isNotEmpty) 'reporter_name': name.trim(),
      if (email != null && email.trim().isNotEmpty)
        'reporter_email': email.trim(),
      if (wa.isNotEmpty) 'reporter_wa': wa,
    };

    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/tickets');
      late final http.Response response;
      if (attachments.isEmpty) {
        response = await _client.post(
          uri,
          headers: _headers(),
          body: jsonEncode(payload),
        );
      } else {
        final request = http.MultipartRequest('POST', uri)
          ..headers.addAll({
            'Accept': 'application/json',
            AppConfig.apiKeyHeader: AppConfig.apiKey,
          })
          ..fields.addAll(
            payload.map((key, value) => MapEntry(key, value.toString())),
          );
        for (final attachment in attachments) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'attachments[]',
              attachment.bytes,
              filename: attachment.name,
            ),
          );
        }
        response = await http.Response.fromStream(await _client.send(request));
      }
      final body = await _parseJson(response);
      _throwForStatus(response, body);

      final raw = _coalesceData(body);
      final ticketNumber =
          (raw is Map ? raw['ticket_number'] ?? raw['ticketNumber'] : raw)
              ?.toString();
      if (ticketNumber == null || ticketNumber.isEmpty) {
        throw const ApiException('Format respons tiket tidak valid.');
      }
      final accessCode = (raw is Map ? raw['access_code'] : null)?.toString();
      return CreateTicketResult(
        ticketNumber: ticketNumber,
        accessCode: accessCode,
      );
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server');
    } on HttpException {
      throw const ApiException('Tidak dapat terhubung ke server');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Tidak dapat terhubung ke server');
    }
  }

  Future<TicketDetail> fetchTicket(String ticketNumber) async {
    final encodedTicket = _encodeTicketPath(ticketNumber.trim());
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/check/$encodedTicket'),
        headers: _headers(),
      );
      final body = await _parseJson(response);
      _throwForStatus(response, body);
      final raw = _coalesceData(body);
      if (raw is! Map) {
        throw const ApiException('Format respons tiket tidak valid.');
      }
      return TicketDetail.fromJson(Map<String, dynamic>.from(raw));
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server');
    } on HttpException {
      throw const ApiException('Tidak dapat terhubung ke server');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Tidak dapat terhubung ke server');
    }
  }

  Future<void> replyTicket(String ticketNumber, String message) async {
    final encodedTicket = _encodeTicketPath(ticketNumber.trim());
    try {
      final response = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/check/$encodedTicket/reply'),
        headers: _headers(),
        body: jsonEncode({'message': message.trim()}),
      );
      final body = await _parseJson(response);
      _throwForStatus(response, body);
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server');
    } on HttpException {
      throw const ApiException('Tidak dapat terhubung ke server');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Tidak dapat terhubung ke server');
    }
  }

  Future<void> completeTicket(String ticketNumber) async {
    final encodedTicket = _encodeTicketPath(ticketNumber.trim());
    try {
      final response = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/check/$encodedTicket/complete'),
        headers: _headers(),
        body: jsonEncode({}),
      );
      final body = await _parseJson(response);
      _throwForStatus(response, body);
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server');
    } on HttpException {
      throw const ApiException('Tidak dapat terhubung ke server');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Tidak dapat terhubung ke server');
    }
  }
}
