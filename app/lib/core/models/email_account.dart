/// 邮箱账号数据模型。
///
/// 字段与导入格式一一对应：`邮箱----密码----client_id----refresh_token----创建时间`。
/// TODO(逻辑接入)：接入持久化后，可切换为 Freezed + json_serializable 生成不可变模型。
class EmailAccount {
  const EmailAccount({
    required this.email,
    required this.password,
    required this.clientId,
    required this.refreshToken,
    required this.createdAt,
    this.activated = false,
  });

  final String email;
  final String password;
  final String clientId;
  final String refreshToken;
  final DateTime createdAt;

  /// 是否已激活（可用）。
  final bool activated;

  /// 帐号 = 邮箱 @ 之前的部分（列表展示用）。
  String get account => email.split('@').first;

  /// 点击复制格式：帐号：xxx 密码：xxx（复制仍用完整密码）。
  String get copyText => '帐号：$account 密码：$password';

  /// 密码打码展示：全部以 `*` 隐藏，最多显示 12 位，不泄露明文。
  String get maskedPassword {
    if (password.isEmpty) return password;
    final n = password.length > 12 ? 12 : password.length;
    return '*' * n;
  }

  EmailAccount copyWith({bool? activated}) => EmailAccount(
        email: email,
        password: password,
        clientId: clientId,
        refreshToken: refreshToken,
        createdAt: createdAt,
        activated: activated ?? this.activated,
      );
}
