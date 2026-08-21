/// Lifecycle state of an account, shown as a colored status dot.
enum AccountStatus { inactive, available, used }

/// A single imported email account.
class EmailAccount {
  EmailAccount({
    required this.email,
    required this.password,
    this.clientId = '',
    this.refreshToken = '',
    this.createdAt = '',
    this.activated = false,
    this.used = false,
    this.apiKey = '',
    this.authLink = '',
    this.quota = '',
    this.activatedAt = '',
  });

  final String email;
  final String password;
  final String clientId;
  final String refreshToken;
  final String createdAt;
  final bool activated;
  final bool used;

  /// API key generated on cun.ai during activation, captured back into the app.
  final String apiKey;

  /// Auth (claim) link extracted from the activation email — kept for the
  /// activation records page.
  final String authLink;

  /// Credit/quota parsed from the activation email (e.g. `$5.800000`), empty
  /// if none was found.
  final String quota;

  /// ISO-8601 timestamp of when the account became activated, used to sort the
  /// activation records (most recent first). Empty for accounts activated
  /// before this field existed.
  final String activatedAt;

  /// Derived lifecycle state. `used` takes precedence over `activated`.
  AccountStatus get status => used
      ? AccountStatus.used
      : activated
          ? AccountStatus.available
          : AccountStatus.inactive;

  /// Account name = email without the domain suffix.
  String get accountName {
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  String get initial =>
      accountName.isNotEmpty ? accountName[0].toUpperCase() : '?';

  EmailAccount copyWith({
    bool? activated,
    bool? used,
    String? apiKey,
    String? authLink,
    String? quota,
    String? activatedAt,
  }) =>
      EmailAccount(
        email: email,
        password: password,
        clientId: clientId,
        refreshToken: refreshToken,
        createdAt: createdAt,
        activated: activated ?? this.activated,
        used: used ?? this.used,
        apiKey: apiKey ?? this.apiKey,
        authLink: authLink ?? this.authLink,
        quota: quota ?? this.quota,
        activatedAt: activatedAt ?? this.activatedAt,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'clientId': clientId,
        'refreshToken': refreshToken,
        'createdAt': createdAt,
        'activated': activated,
        'used': used,
        'apiKey': apiKey,
        'authLink': authLink,
        'quota': quota,
        'activatedAt': activatedAt,
      };

  factory EmailAccount.fromJson(Map<String, dynamic> json) => EmailAccount(
        email: json['email'] as String? ?? '',
        password: json['password'] as String? ?? '',
        clientId: json['clientId'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        activated: json['activated'] as bool? ?? false,
        used: json['used'] as bool? ?? false,
        apiKey: json['apiKey'] as String? ?? '',
        authLink: json['authLink'] as String? ?? '',
        quota: json['quota'] as String? ?? '',
        activatedAt: json['activatedAt'] as String? ?? '',
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
