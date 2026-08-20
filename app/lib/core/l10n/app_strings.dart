import 'package:flutter/widgets.dart';

import '../settings/settings_controller.dart';

/// Lightweight localization table. The base class holds Simplified Chinese
/// (the only shipped locale for now); adding a language later is a matter of
/// subclassing and overriding the getters (see the `zh` / future `en`).
class AppStrings {
  const AppStrings();

  // Common
  String get appName => 'AI Keys';
  String get appSubtitle => '管理你的邮箱与激活状态';
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
  String get statAvailable => '可用数量';
  String get emailListTitle => '邮箱列表';
  String get searchHint => '搜索邮箱或密码';
  String get emptyNoEmails => '还没有邮箱，点击右上角导入';
  String get emptyNoMatch => '没有匹配的邮箱';
  String get statusAvailable => '可用';
  String get statusInactive => '未激活';
  String get activate => '激活';
  String get copied => '已复制到剪贴板';
  String get loadingMore => '加载中...';
  String get noMore => '没有更多了';
  String emailCount(int n) => '共 $n 个邮箱';
  String get confirmDeleteTitle => '删除邮箱';
  String confirmDeleteBody(String name) => '确定要删除 $name 吗？此操作不可撤销。';
  String copyAccountText(String name, String password) => '帐号：$name 密码：$password';

  // Import page
  String get importCsvSection => '导入 CSV 文件';
  String get uploadHint => '点击或拖拽 CSV 文件到此处';
  String get uploadOnlyCsv => '仅支持 .csv 格式';
  String get pasteSection => '或 粘贴数据';
  String get pasteHint => '请粘贴数据，格式如下：\n'
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
  String get warnTitle => '激活过程中请勿退出页面';
  String get warnBody => '请保持网络连接稳定，激活过程可能需要 1-2 分钟';
  String get authLinkTitle => '激活认证链接';
  String get authLinkHint => '点击下方链接，在打开的页面中完成认证';
  String get authLinkOpen => '打开认证链接';

  // Auth webview
  String get webviewTitle => '激活认证';
  String get webviewLoadError => '页面加载失败，请检查网络后重试';
  String get webviewRetry => '重试';
  String get webviewOpenExternal => '在浏览器中打开';

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

/// Convenient access to the active string table: `context.s.importEmail`.
extension AppStringsX on BuildContext {
  AppStrings get s => SettingsController.of(this).strings;
}
