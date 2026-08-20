import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists which mails have been read. The list API exposes no stable id, so
/// we key on `md5(mailbox address + date)` — both fields are present in every
/// list row, so read-state can be reconciled on every load (a content hash of
/// the body could not, since the list response carries no body).
class MailReadStore {
  MailReadStore._();
  static final instance = MailReadStore._();

  static const _key = 'mail_read_ids_v1';
  final Set<String> _ids = {};
  bool _loaded = false;

  /// Read-tracking key derived from the mailbox address and the mail's raw date.
  static String keyFor(String accountEmail, String date) =>
      md5.convert(utf8.encode('$accountEmail|$date')).toString();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _ids.addAll(prefs.getStringList(_key) ?? const []);
    _loaded = true;
  }

  Future<bool> isRead(String id) async {
    await _ensureLoaded();
    return _ids.contains(id);
  }

  Future<void> markRead(String id) async {
    await _ensureLoaded();
    if (_ids.add(id)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _ids.toList());
    }
  }
}
