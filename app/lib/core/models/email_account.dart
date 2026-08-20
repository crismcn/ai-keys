/// A single imported email account.
class EmailAccount {
  EmailAccount({
    required this.email,
    required this.password,
    this.clientId = '',
    this.refreshToken = '',
    this.createdAt = '',
    this.activated = false,
  });

  final String email;
  final String password;
  final String clientId;
  final String refreshToken;
  final String createdAt;
  final bool activated;

  /// Account name = email without the domain suffix.
  String get accountName {
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  String get initial =>
      accountName.isNotEmpty ? accountName[0].toUpperCase() : '?';

  EmailAccount copyWith({bool? activated}) => EmailAccount(
        email: email,
        password: password,
        clientId: clientId,
        refreshToken: refreshToken,
        createdAt: createdAt,
        activated: activated ?? this.activated,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'clientId': clientId,
        'refreshToken': refreshToken,
        'createdAt': createdAt,
        'activated': activated,
      };

  factory EmailAccount.fromJson(Map<String, dynamic> json) => EmailAccount(
        email: json['email'] as String? ?? '',
        password: json['password'] as String? ?? '',
        clientId: json['clientId'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        activated: json['activated'] as bool? ?? false,
      );
}

/// Result summary shown on the import-success screen.
class ImportResult {
  ImportResult({
    required this.added,
    required this.updated,
    required this.failed,
    required this.available,
    required this.total,
  });

  final int added;
  final int updated;
  final int failed;
  final int available;
  final int total;
}
