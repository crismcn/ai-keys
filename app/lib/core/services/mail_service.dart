import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/email_account.dart';
import '../models/mail_message.dart';

/// One page of the mailbox, mapped from the `fetch_emails` response.
class MailPage {
  MailPage({required this.emails, required this.hasMore, required this.total});

  final List<MailMessage> emails;
  final bool hasMore;
  final int total;
}

class MailException implements Exception {
  MailException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the IMAP mail-fetch backend (API.MD #2 / #3). Paginated list.
class MailService {
  static const _fetchUrl = 'https://yovianna.com/api/imap/fetch_emails';
  static const _detailUrl =
      'https://yovianna.com/api/imap/fetch_email_detail';
  static const pageSize = 10;

  /// Fetches one page of the account's inbox. Throws [MailException] on
  /// network / server / decode failures so the UI can show a retry state.
  static Future<MailPage> fetchEmails({
    required EmailAccount account,
    int page = 1,
  }) async {
    late final http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse(_fetchUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': account.email,
              'refresh_token': account.refreshToken,
              'client_id': account.clientId,
              'auth_method': 'auto',
              'folder': 'inbox',
              'page': page,
              'page_size': pageSize,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw MailException('$e');
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw MailException('HTTP ${resp.statusCode}');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw MailException('bad response');
    }

    final rawEmails = data['emails'] as List<dynamic>? ?? const [];
    final emails = rawEmails
        .map((e) => MailMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return MailPage(
      emails: emails,
      hasMore: data['has_more'] as bool? ?? false,
      total: (data['total'] as num?)?.toInt() ?? emails.length,
    );
  }

  /// Fetches the full content of one email (API.MD #3). Throws [MailException]
  /// on network / server / decode failures.
  static Future<MailDetail> fetchEmailDetail({
    required EmailAccount account,
    required String messageId,
    String folder = 'inbox',
  }) async {
    late final http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse(_detailUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': account.email,
              'refresh_token': account.refreshToken,
              'client_id': account.clientId,
              'message_id': messageId,
              'folder': folder,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw MailException('$e');
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw MailException('HTTP ${resp.statusCode}');
    }

    try {
      final data =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return MailDetail.fromJson(data);
    } catch (e) {
      throw MailException('bad response');
    }
  }
}
