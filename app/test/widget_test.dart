// 首页列表交互测试：渲染 / 路由 / 模糊搜索 / 上拉加载。
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_keys_app/app/app.dart';
import 'package:ai_keys_app/app/router/router.dart';
import 'package:ai_keys_app/features/activation/activation_detail_page.dart';

/// 测试用根组件。appRouter 为全局单例，测试间会残留路由状态，
/// 故每次挂载前重置到首页。
Widget _wrap() {
  appRouter.go('/');
  return const ProviderScope(child: AiKeysApp());
}

void main() {
  testWidgets('首页渲染统计卡与邮箱列表', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('AI Keys'), findsOneWidget);
    expect(find.text('邮箱数量'), findsOneWidget);
    expect(find.text('待激活'), findsOneWidget); // 有未激活账号时：彰显一号动作
    expect(find.text('邮箱列表'), findsOneWidget);
    expect(find.text('导入邮箱'), findsOneWidget);
    expect(find.text('搜索邮箱 / 账号'), findsOneWidget);

    // 首批加载 8 条，alice 可见，第 10 条 jack 未加载
    expect(find.text('alice2026'), findsOneWidget);
    expect(find.text('jack.sun'), findsNothing);
  });

  testWidgets('点击导入邮箱跳转到导入页', (tester) async {
    await tester.pumpWidget(_wrap());

    await tester.tap(find.text('导入邮箱'));
    await tester.pumpAndSettle();

    expect(find.text('数据格式'), findsOneWidget);
    expect(find.text('确认导入'), findsOneWidget);
  });

  testWidgets('模糊搜索过滤列表并支持清除', (tester) async {
    await tester.pumpWidget(_wrap());

    await tester.enterText(find.byType(TextField), 'bob');
    await tester.pumpAndSettle();

    expect(find.text('bob.sunshine'), findsOneWidget);
    expect(find.text('alice2026'), findsNothing);
    expect(find.text('匹配 1 个'), findsOneWidget);

    // 清除搜索恢复全部
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('alice2026'), findsOneWidget);
    expect(find.text('共 10 个'), findsOneWidget);
  });

  testWidgets('搜索无结果显示空态', (tester) async {
    await tester.pumpWidget(_wrap());

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('未找到匹配的邮箱'), findsOneWidget);

    // 空态的清除搜索按钮可恢复
    await tester.tap(find.text('清除搜索'));
    await tester.pumpAndSettle();
    expect(find.text('alice2026'), findsOneWidget);
  });

  testWidgets('上拉加载更多并显示全部', (tester) async {
    await tester.pumpWidget(_wrap());

    // 初始只加载前 8 条，第 10 条 jack 尚未加载
    expect(find.text('jack.sun'), findsNothing);

    // 反复滚动到底触发上拉加载（触发阈值 extentAfter<240）
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }

    expect(find.text('jack.sun'), findsOneWidget);
    expect(find.textContaining('已加载全部 10 个'), findsOneWidget);
  });

  testWidgets('130% 字号 + 360dp 窄屏无溢出', (tester) async {
    // 模拟 360×640dp 老款小屏 + 130% 文本缩放
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // 首页
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('邮箱数量'), findsOneWidget);
    expect(find.text('待激活'), findsOneWidget);
    expect(find.text('alice2026'), findsOneWidget);

    // 导入页
    await tester.tap(find.text('导入邮箱'));
    await tester.pumpAndSettle();
    expect(find.text('数据格式'), findsOneWidget);
    // 按钮在折叠区以下：滚动到可见（360dp 高度时 ListView 懒加载）
    await tester.scrollUntilVisible(find.text('确认导入'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('确认导入'), findsOneWidget);

    // 激活详情页
    appRouter.go(ActivationDetailPage.pathOf('alice2026@outlook.com'));
    await tester.pumpAndSettle();
    expect(find.text('激活进度'), findsOneWidget);
    expect(find.text('发送验证码'), findsOneWidget);

    // 任何 RenderFlex 溢出都会在测试里自动抛错（无需显式断言）
  });

  testWidgets('主题切换完整性：light→dark 无残留色', (tester) async {
    // 读取指定文字的生效颜色
    Color effectiveColor(String text) => tester
        .renderObject<RenderParagraph>(find.text(text).first)
        .text
        .style!
        .color!;

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final lightBody = effectiveColor('alice2026');
    final lightSection = effectiveColor('邮箱列表');
    final lightAppBar = effectiveColor('AI Keys');

    // 切深色：ThemeMode.system 跟随平台亮度
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(effectiveColor('alice2026'), isNot(lightBody),
        reason: '正文色应随主题切换');
    expect(effectiveColor('邮箱列表'), isNot(lightSection),
        reason: '区块标题应随主题切换');
    expect(effectiveColor('AI Keys'), isNot(lightAppBar),
        reason: '标题应随主题切换');
  });
}