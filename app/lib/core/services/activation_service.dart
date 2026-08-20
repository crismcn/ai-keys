import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/email_account.dart';
import '../models/mail_message.dart';
import 'mail_service.dart';

/// Verification code + the message it came from, produced by
/// [ActivationService.awaitVerificationCode].
class VerificationResult {
  const VerificationResult({required this.messageId, required this.code});
  final String messageId;
  final String code;
}

class ActivationException implements Exception {
  ActivationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Drives the real activation flow against the CUN.AI + IMAP backends
/// (API.MD #1/#2/#3/#4/#5). Mail polling reuses [MailService].
class ActivationService {
  static const _verifyUrl = 'https://www.cun.ai/api/verification';
  static const _registerUrl = 'https://www.cun.ai/api/user/register';

  /// Subject of the code email (API.MD #4) and prefix of the claim email (#5).
  static const _codeSubject = 'CUN.AI邮箱验证邮件';
  static const _claimPrefix = 'Verify your email to claim';

  /// Step 1 — request a verification code be emailed (API.MD #1).
  static Future<void> sendVerification(EmailAccount account) async {
    final uri = Uri.parse(_verifyUrl).replace(
      queryParameters: {'email': account.email, 'turnstile': ''},
    );
    late final http.Response resp;
    try {
      resp = await http.get(uri).timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ActivationException('发送验证码请求失败：$e');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ActivationException('发送验证码失败（HTTP ${resp.statusCode}）');
    }
    if (!_isSuccess(resp.body)) {
      throw ActivationException(_messageOf(resp.body) ?? '发送验证码失败');
    }
  }

  /// Step 2 — poll the inbox for the code email and extract the code (#2/#3/#4).
  /// Only emails whose `date` is after [since] (the moment activation started)
  /// count, so a stale code from an earlier attempt is never picked up.
  /// Polls every 30s for ~5 minutes.
  static Future<VerificationResult> awaitVerificationCode(
    EmailAccount account, {
    required DateTime since,
    required bool Function() isCancelled,
  }) async {
    final mail = await _pollForEmail(
      account,
      (m) => m.cleanSubject == _codeSubject && _isAfter(m.date, since),
      interval: const Duration(seconds: 30),
      maxAttempts: 11,
      isCancelled: isCancelled,
    );
    if (mail == null) throw ActivationException('未能收取到验证码，请重试');

    final MailDetail detail;
    try {
      detail = await MailService.fetchEmailDetail(
        account: account,
        messageId: mail.messageId,
      );
    } on MailException catch (e) {
      throw ActivationException('读取验证码邮件失败：$e');
    }

    final code = _extractCode('${detail.html}\n${detail.body}');
    if (code == null) throw ActivationException('验证码邮件中未找到验证码');
    return VerificationResult(messageId: mail.messageId, code: code);
  }

  /// Step 3 — submit registration with the code (API.MD #4).
  static Future<void> register({
    required EmailAccount account,
    required String messageId,
    required String code,
  }) async {
    late final http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse(_registerUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': account.email,
              'username': account.accountName,
              'password': account.password,
              'message_id': messageId,
              'verification_code': code,
              'utm_source': 'linuxdo',
              'utm_medium': 'free',
              'turnstile': '',
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ActivationException('注册请求失败：$e');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ActivationException('注册失败（HTTP ${resp.statusCode}）');
    }
    if (!_isSuccess(resp.body)) {
      throw ActivationException(_messageOf(resp.body) ?? '注册失败');
    }
  }

  /// Step 4 — poll for the "claim" email (#5.1) and extract its auth link (#5.2).
  /// Like step 2, only emails newer than [since] are considered. Polls every
  /// 20s for ~5 minutes.
  static Future<String> awaitAuthLink(
    EmailAccount account, {
    required DateTime since,
    required bool Function() isCancelled,
  }) async {
    final mail = await _pollForEmail(
      account,
      (m) => m.cleanSubject.startsWith(_claimPrefix) && _isAfter(m.date, since),
      interval: const Duration(seconds: 20),
      maxAttempts: 16,
      isCancelled: isCancelled,
    );
    if (mail == null) throw ActivationException('未获取到认证链接，请重试');

    final MailDetail detail;
    try {
      detail = await MailService.fetchEmailDetail(
        account: account,
        messageId: mail.messageId,
      );
    } on MailException catch (e) {
      throw ActivationException('读取认证邮件失败：$e');
    }

    final link = _extractLink('${detail.html}\n${detail.body}');
    if (link == null) throw ActivationException('认证邮件中未找到认证链接');
    return link;
  }

  /// Polls page 1 of the inbox until [test] matches an email, [maxAttempts] is
  /// reached, or [isCancelled] fires. Returns the match, or null on timeout.
  static Future<MailMessage?> _pollForEmail(
    EmailAccount account,
    bool Function(MailMessage) test, {
    required Duration interval,
    required int maxAttempts,
    required bool Function() isCancelled,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (isCancelled()) return null;
      try {
        final page = await MailService.fetchEmails(account: account, page: 1);
        for (final mail in page.emails) {
          if (test(mail)) return mail;
        }
      } on MailException {
        // Transient fetch failure — keep polling until attempts run out.
      }
      if (isCancelled()) return null;
      if (attempt < maxAttempts - 1) await Future<void>.delayed(interval);
    }
    return null;
  }

  /// True when the mail's raw [date] header parses to an instant after [since].
  /// `DateTime.isAfter` compares absolute instants, so the timezone offset in
  /// the header and the local [since] are handled correctly.
  static bool _isAfter(String date, DateTime since) {
    final d = DateTime.tryParse(date);
    return d != null && d.isAfter(since);
  }

  /// Extracts a verification code: a 6-digit run first, else any 4–8 digit run.
  static String? _extractCode(String text) {
    final six = RegExp(r'\b(\d{6})\b').firstMatch(text);
    if (six != null) return six.group(1);
    final any = RegExp(r'(\d{4,8})').firstMatch(text);
    return any?.group(1);
  }

  /// Extracts the first http(s) URL, preferring ones that look like the claim
  /// link (containing `claim` or `cun.ai`).
  static String? _extractLink(String text) {
    final urls = RegExp(r'''https?://[^\s"'<>)]+''')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    if (urls.isEmpty) return null;
    for (final u in urls) {
      final lower = u.toLowerCase();
      if (lower.contains('claim') || lower.contains('cun.ai')) return u;
    }
    return urls.first;
  }

  /// True unless the JSON body explicitly carries `"success": false`.
  static bool _isSuccess(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['success'] == false) return false;
    } catch (_) {
      // Non-JSON 2xx body — treat as success.
    }
    return true;
  }

  static String? _messageOf(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        final msg = data['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
    } catch (_) {}
    return null;
  }
}
