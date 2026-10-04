import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_item.dart';

class HistoryStorage {
  HistoryStorage._();

  static final HistoryStorage instance = HistoryStorage._();

  static const String _storageKey = 'melati_history';

  Future<List<HistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final items = decoded
        .whereType<Map>()
        .map((item) => HistoryItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> addItem(HistoryItem item) async {
    final current = await loadHistory();
    final filtered = current.where((entry) => entry.ticketNumber != item.ticketNumber).toList();
    filtered.add(item);
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save(filtered);
  }

  Future<void> removeItem(String ticketNumber) async {
    final current = await loadHistory();
    final filtered = current.where((entry) => entry.ticketNumber != ticketNumber).toList();
    await _save(filtered);
  }

  Future<void> _save(List<HistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
