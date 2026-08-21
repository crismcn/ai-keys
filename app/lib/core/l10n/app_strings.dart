import 'package:flutter/widgets.dart';

import '../settings/settings_controller.dart';

/// Lightweight localization table. The base class holds Simplified Chinese;
/// [AppStringsEn] subclasses it to provide English. The active table is chosen
/// by [SettingsController] from the current locale.
class AppStrings {
  const AppStrings();

  // Common
  String get appName => 'AI Mails';
  String get appSubtitle => '最懂你的邮箱批量管理工具';
  String get cancel => '取消';
  String get delete => '删除';

  // Bottom navigation
  String get navEmails => '邮箱';
  String get navActivation => '激活记录';
  String get navSettings => '设置';

  // Home
  String get importEmail => '导入邮箱';
  String get statEmailCount => '邮箱数量';
  String get statTotal => '总数量';
  String get statActivated => '已激活数量';
  String get statPending => '待使用数量';
  String get statAvailable => '可用数量';
  String get statInactive => '未激活数量';
  String get statUsed => '已使用数量';
  String get emailListTitle => '邮箱列表';
  String get searchHint => '搜索邮箱或密码';
  String get emptyNoEmails => '还没有邮箱，点击右上角导入';
  String get emptyNoMatch => '没有匹配的邮箱';
  String get statusAvailable => '可用';
  String get statusInactive => '未激活';
  String get statusUsed => '已使用';
  String get activate => '激活';
  String get copied => '已复制到剪贴板';
  String get loadingMore => '加载中...';
  String get noMore => '没有更多了';
  String emailCount(int n) => '共 $n 个邮箱';
  String get confirmDeleteTitle => '删除邮箱';
  String confirmDeleteBody(String name) => '确定要删除 $name 吗？此操作不可撤销。';
  String get confirmActivateTitle => '设为已激活';
  String confirmActivateBody(String name) => '确定将 $name 标记为已激活状态吗？';
  String get activatedToast => '已设为激活状态';
  String get markUsed => '标记已使用';
  String get confirmUsedTitle => '设为已使用';
  String confirmUsedBody(String name) => '确定将 $name 标记为已使用状态吗？';
  String get usedToast => '已设为已使用状态';
  String copyAccountText(String name, String password) =>
      '帐号：$name 密码：$password';

  // Import page
  String get importCsvSection => '导入 CSV 文件';
  String get uploadHint => '点击或拖拽 CSV 文件到此处';
  String get uploadOnlyCsv => '仅支持 .csv 格式';
  String get pasteSection => '或 粘贴数据';
  String get pasteHint =>
      '请粘贴数据，格式如下：\n'
      '邮箱----密码----client_id----refresh_token----创建时间\n\n'
      'user1@example.com----123456----xxxx----xxxx----2024-01-01 10:00:00\n'
      'user2@example.com----123456----xxxx----xxxx----2024-01-01 10:00:00';
  String get formatSection => '格式说明';
  String get fieldEmail => '邮箱';
  String get fieldEmailDesc => '邮箱地址';
  String get fieldPassword => '密码';
  String get fieldPasswordDesc => '邮箱密码';
  String get fieldClientId => 'client_id';
  String get fieldClientIdDesc => '客户端 ID';
  String get fieldRefreshToken => 'refresh_token';
  String get fieldRefreshTokenDesc => '刷新令牌';
  String get fieldCreatedAt => '创建时间';
  String get fieldCreatedAtDesc => '创建时间，格式：yyyy-MM-dd HH:mm:ss';
  String get importing => '导入中...';
  String get privacyPrefix => '导入即表示您已阅读并同意 ';
  String get privacyPolicy => '数据隐私政策';

  // Import success
  String get importSuccess => '导入成功';
  String importedCount(int n) => '共导入 $n 个邮箱';
  String get summaryAdded => '新增邮箱';
  String get summaryUpdated => '更新邮箱';
  String get summaryFailed => '失败邮箱';
  String get summaryAvailable => '可用邮箱';
  String get viewList => '查看邮箱列表';
  String get continueImport => '继续导入';

  // Mail list
  String get mailListTitle => '邮件列表';
  String get mailLoading => '正在收取邮件...';
  String get mailEmpty => '暂无邮件';
  String get mailLoadError => '邮件加载失败，请检查网络后重试';
  String get mailRetry => '重试';
  String mailCount(int n) => '共 $n 封邮件';
  // Mail detail
  String get mailFrom => '发件人';
  String get mailTo => '收件人';
  String get mailNoBody => '暂无正文内容';

  // Activation detail
  String get activationTitle => '激活详情';
  String get step1Title => '发送验证码阶段';
  String get step1Hint => '正在向邮箱发送验证码...';
  String get step1Done => '验证码已发送';
  String get step2Title => '收取验证码阶段';
  String get step2Hint => '等待接收验证码...';
  String get step2Done => '验证码已收取';
  String get step3Title => '脚本注册阶段';
  String get step3Hint => '准备执行注册脚本...';
  String get step3Done => '脚本注册完成';
  String get step4Title => '激活认证阶段';
  String get step4Hint => '等待激活认证...';
  String get step4Done => '激活认证通过';
  String get step1Error => '发送验证码失败，请重试';
  String get step2Error => '未能收取到验证码，请重试';
  String get step3Error => '注册失败，请重试';
  String get step4Error => '未获取到认证链接，请重试';
  String get activationRetry => '重试';
  String get warnTitle => '激活过程中请勿退出页面';
  String get warnBody => '请保持网络连接稳定，激活过程可能需要 1-2 分钟';
  String get authLinkTitle => '激活认证链接';
  String get authLinkHint => '点击下方链接，在打开的页面中完成认证';
  String get authLinkOpen => '打开认证链接';
  String get apiKeyLabel => 'API 密钥';
  String get apiKeySaved => '密钥已保存到邮箱';
  String get copyKey => '复制密钥';

  // Activation records
  String get quotaLabel => '额度';
  String get recordsEmpty => '还没有激活记录';
  String get exportRecords => '导出';
  String get recordsTabUsed => '已使用';
  String get recordsTabPending => '待使用';
  String get keyNotCreated => '去创建';
  String copyMailboxInfo({
    required String account,
    required String email,
    required String password,
    required String key,
  }) =>
      '帐号：$account\n邮箱：$email\n密码：$password\n密钥：$key';

  // Auth webview
  String get webviewTitle => '激活认证';
  String get webviewLoadError => '页面加载失败，请检查网络后重试';
  String get webviewRetry => '重试';
  String get webviewOpenExternal => '在浏览器中打开';
  String get webPageTitle => '网页';

  // Settings
  String get settingsTitle => '设置';
  String get sectionAppearance => '外观';
  String get themeLight => '浅色';
  String get themeDark => '深色';
  String get themeSystem => '跟随系统';
  String get sectionLanguage => '语言';
  String get langZh => '简体中文';
  String get langEn => 'English';
  String get langEnComingSoon => '即将支持';
  String get sectionAbout => '关于';
  String get aboutVersion => '版本';

  // Placeholder tabs
  String comingSoon(String title) => '$title 功能即将上线';
}

/// English localization. Overrides every string in [AppStrings].
class AppStringsEn extends AppStrings {
  const AppStringsEn();

  // Common
  @override
  String get appName => 'AI Mails';
  @override
  String get appSubtitle => 'The smartest bulk mailbox manager';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';

  // Bottom navigation
  @override
  String get navEmails => 'Mailboxes';
  @override
  String get navActivation => 'Activations';
  @override
  String get navSettings => 'Settings';

  // Home
  @override
  String get importEmail => 'Import';
  @override
  String get statEmailCount => 'Mailboxes';
  @override
  String get statTotal => 'Total';
  @override
  String get statActivated => 'Activated';
  @override
  String get statPending => 'Pending';
  @override
  String get statAvailable => 'Available';
  @override
  String get statInactive => 'Inactive';
  @override
  String get statUsed => 'Used';
  @override
  String get emailListTitle => 'Mailbox List';
  @override
  String get searchHint => 'Search email or password';
  @override
  String get emptyNoEmails => 'No mailboxes yet — tap Import at the top right';
  @override
  String get emptyNoMatch => 'No matching mailboxes';
  @override
  String get statusAvailable => 'Available';
  @override
  String get statusInactive => 'Inactive';
  @override
  String get statusUsed => 'Used';
  @override
  String get activate => 'Activate';
  @override
  String get copied => 'Copied to clipboard';
  @override
  String get loadingMore => 'Loading...';
  @override
  String get noMore => 'No more';
  @override
  String emailCount(int n) => '$n mailbox${n == 1 ? '' : 'es'}';
  @override
  String get confirmDeleteTitle => 'Delete Mailbox';
  @override
  String confirmDeleteBody(String name) =>
      'Delete $name? This action cannot be undone.';
  @override
  String get confirmActivateTitle => 'Mark as Activated';
  @override
  String confirmActivateBody(String name) => 'Mark $name as activated?';
  @override
  String get activatedToast => 'Marked as activated';
  @override
  String get markUsed => 'Mark Used';
  @override
  String get confirmUsedTitle => 'Mark as Used';
  @override
  String confirmUsedBody(String name) => 'Mark $name as used?';
  @override
  String get usedToast => 'Marked as used';
  @override
  String copyAccountText(String name, String password) =>
      'Account: $name Password: $password';
  // _EN_IMPORT_
  // Import page
  @override
  String get importCsvSection => 'Import CSV File';
  @override
  String get uploadHint => 'Tap or drag a CSV file here';
  @override
  String get uploadOnlyCsv => 'Only .csv format is supported';
  @override
  String get pasteSection => 'Or paste data';
  @override
  String get pasteHint =>
      'Paste data in the following format:\n'
      'email----password----client_id----refresh_token----created_at\n\n'
      'user1@example.com----123456----xxxx----xxxx----2024-01-01 10:00:00\n'
      'user2@example.com----123456----xxxx----xxxx----2024-01-01 10:00:00';
  @override
  String get formatSection => 'Format';
  @override
  String get fieldEmail => 'Email';
  @override
  String get fieldEmailDesc => 'Email address';
  @override
  String get fieldPassword => 'Password';
  @override
  String get fieldPasswordDesc => 'Mailbox password';
  @override
  String get fieldClientId => 'client_id';
  @override
  String get fieldClientIdDesc => 'Client ID';
  @override
  String get fieldRefreshToken => 'refresh_token';
  @override
  String get fieldRefreshTokenDesc => 'Refresh token';
  @override
  String get fieldCreatedAt => 'Created At';
  @override
  String get fieldCreatedAtDesc => 'Created time, format: yyyy-MM-dd HH:mm:ss';
  @override
  String get importing => 'Importing...';
  @override
  String get privacyPrefix => 'By importing you agree to the ';
  @override
  String get privacyPolicy => 'Data Privacy Policy';

  // Import success
  @override
  String get importSuccess => 'Import Successful';
  @override
  String importedCount(int n) => 'Imported $n mailbox${n == 1 ? '' : 'es'}';
  @override
  String get summaryAdded => 'Added';
  @override
  String get summaryUpdated => 'Updated';
  @override
  String get summaryFailed => 'Failed';
  @override
  String get summaryAvailable => 'Available';
  @override
  String get viewList => 'View Mailbox List';
  @override
  String get continueImport => 'Continue Importing';
  // _EN_MAIL_
  // Mail list
  @override
  String get mailListTitle => 'Mail List';
  @override
  String get mailLoading => 'Fetching mail...';
  @override
  String get mailEmpty => 'No mail';
  @override
  String get mailLoadError =>
      'Failed to load mail. Check your network and retry';
  @override
  String get mailRetry => 'Retry';
  @override
  String mailCount(int n) => '$n message${n == 1 ? '' : 's'}';
  // Mail detail
  @override
  String get mailFrom => 'From';
  @override
  String get mailTo => 'To';
  @override
  String get mailNoBody => 'No content';

  // Activation detail
  @override
  String get activationTitle => 'Activation Details';
  @override
  String get step1Title => 'Send Verification Code';
  @override
  String get step1Hint => 'Sending verification code to the mailbox...';
  @override
  String get step1Done => 'Verification code sent';
  @override
  String get step2Title => 'Receive Verification Code';
  @override
  String get step2Hint => 'Waiting for the verification code...';
  @override
  String get step2Done => 'Verification code received';
  @override
  String get step3Title => 'Script Registration';
  @override
  String get step3Hint => 'Preparing to run the registration script...';
  @override
  String get step3Done => 'Registration complete';
  @override
  String get step4Title => 'Activation Verification';
  @override
  String get step4Hint => 'Waiting for activation verification...';
  @override
  String get step4Done => 'Activation verified';
  // _EN_STEP_ERR_
  @override
  String get step1Error => 'Failed to send verification code, please retry';
  @override
  String get step2Error => 'Could not receive verification code, please retry';
  @override
  String get step3Error => 'Registration failed, please retry';
  @override
  String get step4Error => 'Could not get verification link, please retry';
  @override
  String get activationRetry => 'Retry';
  @override
  String get warnTitle => 'Do not leave this page during activation';
  @override
  String get warnBody =>
      'Keep your network stable; activation may take 1-2 minutes';
  @override
  String get authLinkTitle => 'Activation Verification Link';
  @override
  String get authLinkHint =>
      'Tap the link below and complete verification on the page that opens';
  @override
  String get authLinkOpen => 'Open Verification Link';
  @override
  String get apiKeyLabel => 'API Key';
  @override
  String get apiKeySaved => 'API key saved to mailbox';
  @override
  String get copyKey => 'Copy key';

  // Activation records
  @override
  String get quotaLabel => 'Credit';
  @override
  String get recordsEmpty => 'No activation records yet';
  @override
  String get exportRecords => 'Export';
  @override
  String get recordsTabUsed => 'Used';
  @override
  String get recordsTabPending => 'Pending';
  @override
  String get keyNotCreated => 'Create';
  @override
  String copyMailboxInfo({
    required String account,
    required String email,
    required String password,
    required String key,
  }) =>
      'Account: $account\nEmail: $email\nPassword: $password\nKey: $key';

  // Auth webview
  @override
  String get webviewTitle => 'Activation Verification';
  @override
  String get webviewLoadError =>
      'Failed to load page. Check your network and retry';
  @override
  String get webviewRetry => 'Retry';
  @override
  String get webviewOpenExternal => 'Open in browser';
  @override
  String get webPageTitle => 'Web Page';

  // Settings
  @override
  String get settingsTitle => 'Settings';
  @override
  String get sectionAppearance => 'Appearance';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeSystem => 'System';
  @override
  String get sectionLanguage => 'Language';
  @override
  String get langZh => '简体中文';
  @override
  String get langEn => 'English';
  @override
  String get langEnComingSoon => 'Coming soon';
  @override
  String get sectionAbout => 'About';
  @override
  String get aboutVersion => 'Version';

  // Placeholder tabs
  @override
  String comingSoon(String title) => '$title is coming soon';
}




/// Convenient access to the active string table: `context.s.importEmail`.
extension AppStringsX on BuildContext {
  AppStrings get s => SettingsController.of(this).strings;
}
