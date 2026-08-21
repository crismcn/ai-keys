import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/email_account.dart';
import '../utils/import_parser.dart';

/// Central store for imported email accounts, backed by SharedPreferences.
class EmailStore extends ChangeNotifier {
  static const _key = 'email_accounts_v1';

  final List<EmailAccount> _accounts = [];
  bool _loaded = false;

  List<EmailAccount> get accounts => List.unmodifiable(_accounts);
  bool get loaded => _loaded;

  int get total => _accounts.length;
  int get available => _accounts.where((a) => a.activated).length;

  /// Case-insensitive filter over account name / email / password.
  List<EmailAccount> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return accounts;
    return _accounts
        .where((a) =>
            a.email.toLowerCase().contains(q) ||
            a.password.toLowerCase().contains(q))
        .toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      _accounts
        ..clear()
        ..addAll(list.map((e) =>
            EmailAccount.fromJson(Map<String, dynamic>.from(e as Map))));
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_accounts.map((e) => e.toJson()).toList()),
    );
  }

  /// Imports parsed rows, merging by email. Returns a summary.
  Future<ImportResult> importFrom(String raw) async {
    final incoming = ImportParser.parse(raw);
    var added = 0;
    var updated = 0;
    for (final acc in incoming) {
      final idx = _accounts.indexWhere(
          (a) => a.email.toLowerCase() == acc.email.toLowerCase());
      if (idx >= 0) {
        _accounts[idx] = acc.copyWith(
          activated: _accounts[idx].activated,
          used: _accounts[idx].used,
        );
        updated++;
      } else {
        _accounts.add(acc);
        added++;
      }
    }
    await _persist();
    notifyListeners();
    return ImportResult(
      added: added,
      updated: updated,
      failed: 0,
      available: available,
      total: total,
    );
  }

  Future<void> remove(EmailAccount account) async {
    _accounts.removeWhere((a) => a.email == account.email);
    await _persist();
    notifyListeners();
  }

  Future<void> markActivated(EmailAccount account) async {
    final idx = _accounts.indexWhere((a) => a.email == account.email);
    if (idx >= 0) {
      _accounts[idx] = _accounts[idx].copyWith(activated: true);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> markUsed(EmailAccount account) async {
    final idx = _accounts.indexWhere((a) => a.email == account.email);
    if (idx >= 0) {
      // "Used" implies the account was activated first.
      _accounts[idx] = _accounts[idx].copyWith(activated: true, used: true);
      await _persist();
      notifyListeners();
    }
  }
}
