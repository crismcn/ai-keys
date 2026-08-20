import '../models/email_account.dart';

/// Parses pasted text or CSV content into [EmailAccount]s.
///
/// Expected line format (fields separated by `----`):
///   email----password----client_id----refresh_token----createdAt
/// Falls back to comma / tab separated values for `.csv` files.
class ImportParser {
  static List<EmailAccount> parse(String raw) {
    final accounts = <EmailAccount>[];
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Skip an obvious header row.
      if (trimmed.startsWith('邮箱') || trimmed.toLowerCase().startsWith('email')) {
        continue;
      }

      final parts = _split(trimmed);
      if (parts.isEmpty || parts[0].isEmpty || !parts[0].contains('@')) {
        continue;
      }

      accounts.add(
        EmailAccount(
          email: parts[0],
          password: parts.length > 1 ? parts[1] : '',
          clientId: parts.length > 2 ? parts[2] : '',
          refreshToken: parts.length > 3 ? parts[3] : '',
          createdAt: parts.length > 4 ? parts[4] : '',
        ),
      );
    }
    return accounts;
  }

  static List<String> _split(String line) {
    if (line.contains('----')) {
      return line.split('----').map((e) => e.trim()).toList();
    }
    if (line.contains(',')) {
      return line.split(',').map((e) => e.trim()).toList();
    }
    if (line.contains('\t')) {
      return line.split('\t').map((e) => e.trim()).toList();
    }
    return [line.trim()];
  }
}
