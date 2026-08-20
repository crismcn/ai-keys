/// A single received email, mapped from the `fetch_emails` API response.
class MailMessage {
  const MailMessage({
    required this.messageId,
    required this.folder,
    required this.subject,
    required this.from,
    required this.date,
    required this.isRead,
  });

  final String messageId;
  final String folder;
  final String subject; // raw header (may contain CRLF folding)
  final String from; // raw "Name <email>" header
  final String date; // raw ISO-8601 string
  final bool isRead;

  bool get unread => !isRead;

  /// Display name parsed from the raw [from] header (`Name <email>`).
  String get sender {
    final raw = from.trim();
    final lt = raw.indexOf('<');
    var name = (lt > 0 ? raw.substring(0, lt) : raw).replaceAll('"', '').trim();
    if (name.isEmpty) {
      final addr = senderEmail;
      final at = addr.indexOf('@');
      name = at > 0 ? addr.substring(0, at) : addr;
    }
    return name;
  }

  /// Email address extracted from the raw [from] header.
  String get senderEmail {
    final lt = from.indexOf('<');
    final gt = from.indexOf('>');
    if (lt >= 0 && gt > lt) return from.substring(lt + 1, gt).trim();
    return from.trim();
  }

  /// Subject collapsed to a single line (headers can be CRLF-folded).
  String get cleanSubject => subject.replaceAll(RegExp(r'\s+'), ' ').trim();

  String get initial {
    final s = sender;
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }

  /// Short display time derived from [date]: `HH:mm` if today, else `MM-dd`.
  String get displayTime {
    final dt = DateTime.tryParse(date);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return '${two(local.hour)}:${two(local.minute)}';
    }
    return '${two(local.month)}-${two(local.day)}';
  }

  MailMessage copyWith({bool? isRead}) => MailMessage(
        messageId: messageId,
        folder: folder,
        subject: subject,
        from: from,
        date: date,
        isRead: isRead ?? this.isRead,
      );

  factory MailMessage.fromJson(Map<String, dynamic> json) => MailMessage(
        messageId: json['message_id'] as String? ?? '',
        folder: json['folder'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        from: json['from'] as String? ?? '',
        date: json['date'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
      );
}

/// Full email content, mapped from the `fetch_email_detail` response (#3).
class MailDetail {
  const MailDetail({
    required this.messageId,
    required this.subject,
    required this.from,
    required this.to,
    required this.date,
    required this.body,
    required this.html,
  });

  final String messageId;
  final String subject;
  final String from;
  final String to;
  final String date;
  final String body;
  final String html;

  String get cleanSubject => subject.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Full display timestamp: `yyyy-MM-dd HH:mm`.
  String get displayDate {
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} '
        '${two(l.hour)}:${two(l.minute)}';
  }

  /// Readable body: prefer the plain [body]; otherwise strip tags from [html].
  String get displayBody {
    if (body.trim().isNotEmpty) return body.trim();
    if (html.trim().isNotEmpty) {
      return html
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    return '';
  }

  factory MailDetail.fromJson(Map<String, dynamic> json) => MailDetail(
        messageId: json['message_id'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        from: json['from'] as String? ?? '',
        to: json['to'] as String? ?? '',
        date: json['date'] as String? ?? '',
        body: json['body'] as String? ?? '',
        html: json['html'] as String? ?? '',
      );
}
