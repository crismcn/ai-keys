# AI Keys Flutter UI 美化 Spec
> 用于 Claude Code / Codex 直接执行
> 目标：将现有 AI Keys App 从“紫色 AI 风格”改造成「简约、专业、高级、耐看」的现代工具型 App。
> 核心原则：保留现有业务逻辑和功能，只重构视觉层、组件层和交互细节。

---

## 0. 执行要求

你现在负责对现有 Flutter 项目进行 UI/UX 重构。

### 必须遵守

1. **先阅读现有项目代码，再修改。**
2. 不要随意修改业务逻辑、API、数据模型、状态管理、路由和持久化逻辑。
3. 优先复用现有功能，只调整 UI、Theme、Widget 结构和交互反馈。
4. 不要为了美化引入大量新的第三方依赖。
5. 优先使用 Flutter Material 3 原生组件和现有依赖。
6. 如果项目已经有 Theme / Design Token / 公共组件，优先扩展，不要重复创建。
7. 所有颜色、圆角、间距、字体尺寸尽量通过 Theme / Design Tokens 统一管理。
8. 修改完成后检查：
   - 小屏幕是否溢出
   - 长邮箱名称是否溢出
   - 键盘弹出时是否正常
   - Dark Mode 是否正常
   - ListView / ScrollView 是否正常
   - 激活按钮是否正常
   - 搜索和筛选是否正常
   - 状态变化是否有视觉反馈

---

# 1. 产品视觉定位

## 产品

AI Keys

## 产品类型

AI 邮箱 / AI 账号 / Key 管理工具。

## 视觉关键词

- 简约
- 高级
- 专业
- 干净
- 克制
- 现代
- 工具感
- 高可读性
- 长时间使用不疲劳

## 明确禁止

不要做成：

- AI 紫色科技风
- 大面积紫色渐变
- 蓝紫渐变背景
- 玻璃拟态堆叠
- 发光按钮
- Neon
- 过度阴影
- 过度圆角
- 大量渐变
- 大量装饰性图形
- 卡片里面再套卡片
- “一眼 AI 生成”的视觉效果

目标是：

> 像一款成熟的商业效率工具，而不是 AI Demo。

---

# 2. 整体设计方向

参考：

- Linear
- Raycast
- Arc
- Notion
- Apple Settings
- Stripe Dashboard
- 现代 SaaS 管理工具

但不要直接复制任何产品。

整体应该采用：

```text
大面积中性色背景
+
白色 / 浅灰内容区域
+
单一品牌色
+
少量状态色
+
细边框
+
轻阴影
+
清晰 Typography
```

---

# 3. Color System

## Light Mode

推荐：

```text
Background       #F7F8FA
Surface          #FFFFFF
Surface Secondary #F2F4F7

Text Primary     #111827
Text Secondary   #667085
Text Tertiary    #98A2B3

Border           #E5E7EB
Border Light     #EEF0F3

Primary          #2563EB
Primary Hover    #1D4ED8
Primary Soft     #EFF6FF

Success          #16A34A
Success Soft     #ECFDF3

Warning          #F59E0B
Warning Soft     #FFFAEB

Error            #DC2626
Error Soft       #FEF2F2
```

### 颜色原则

Primary 只用于：

- 主要按钮
- 当前导航
- 关键操作
- 少量重点图标

不要让 Primary 覆盖整个页面。

---

# 4. Dark Mode

Dark Mode 不要使用紫色背景。

推荐：

```text
Background       #0F1115
Surface          #171A21
Surface Secondary #1D212A

Text Primary     #F8FAFC
Text Secondary   #A1A8B3
Text Tertiary    #667085

Border           #2A2F38

Primary          #60A5FA
Success          #34D399
Warning          #FBBF24
Error            #F87171
```

Dark Mode 依然保持：

> 克制、专业、低饱和。

---

# 5. Typography

优先使用系统字体。

中文：

```text
PingFang SC
Microsoft YaHei
Noto Sans CJK SC
```

英文：

```text
SF Pro
Inter
Roboto
```

不要大量使用超粗字体。

## 推荐层级

```text
Page Title       24px / 700
Section Title    20px / 600
Card Title       16px / 600
Body             14px / 400~500
Caption          12px / 400
Large Number     32~40px / 700
```

数字要明显，但不要做成营销 Dashboard。

---

# 6. Spacing System

统一使用 4 / 8 spacing system：

```text
4
8
12
16
20
24
32
40
48
```

页面主要 Padding：

```text
16px
```

Section 间距：

```text
24px
```

Card 内部：

```text
16px
```

列表 Item 间距：

```text
8~12px
```

避免随意出现：

```text
13px
17px
19px
23px
27px
```

---

# 7. Border Radius

整体不要过度圆润。

推荐：

```text
Small Button       8px
Input              10px
List Card          12px
Statistics Card    14px
Large Container    16px
Bottom Navigation  16px
```

不要使用：

```text
32px
40px
50px
```

这种非常明显的 AI 卡片风。

---

# 8. Shadow

使用非常轻的阴影。

Light Mode：

```text
0 1px 3px rgba(16, 24, 40, 0.06)
0 4px 12px rgba(16, 24, 40, 0.05)
```

不要出现明显的紫色 Glow。

禁止：

```text
box-shadow: 0 0 30px purple
```

---

# 9. 首页 Header

现有：

```text
[Logo] AI Keys                  [🌙] [+ 导入邮箱]
```

调整为：

```text
[Logo] AI Keys                  [Theme] [导入邮箱]
       管理你的 AI 访问密钥
```

### Logo

使用简洁的深色 Logo 容器。

推荐：

```text
40 x 40
Radius 10~12
```

不要：

- 发光
- 渐变
- 大面积紫色

### AI Keys

标题：

```text
20~22px
FontWeight 700
```

副标题：

```text
12~13px
TextSecondary
```

### 导入邮箱

使用 OutlinedButton / FilledButton 风格。

推荐：

```text
+ 导入邮箱
```

按钮：

```text
高度 40~44
Radius 10
Border 1px
Primary
```

不要做巨大渐变按钮。

---

# 10. Statistics Cards

现有：

```text
邮箱数量
10

待激活
8
```

改成更加克制的 Dashboard Card。

推荐：

```text
┌──────────────────────┐
│  ✉  邮箱数量          │
│                      │
│  10                  │
│  较昨日 +2 ↑          │
└──────────────────────┘
```

两个卡片：

```text
邮箱数量
待激活
```

### 设计

背景：

```text
#FFFFFF
```

边框：

```text
#E5E7EB
```

少量阴影。

图标可以有浅色背景：

```text
Primary Soft
Success Soft
```

数字：

```text
32~36px
fontWeight 700
```

不要渐变。

不要发光。

不要巨大背景插画。

---

# 11. 邮箱列表区域

这是页面最重要的内容区域。

结构：

```text
邮箱列表                         共 10 个

[ 🔍 搜索邮箱 / 账号... ] [筛选]

┌─────────────────────────────────┐
│ A    alice2026                  │
│      ali****@gmail.com          │
│      ● 可用                     │
│                            ⋮    │
└─────────────────────────────────┘
```

### List Container

白色 Surface。

Border：

```text
#E5E7EB
```

Radius：

```text
16px
```

不要使用深色大块背景。

---

# 12. Search Bar

搜索框：

```text
高度 48~52px
Radius 10~12px
Background #F8FAFC
Border #E5E7EB
```

左侧：

```text
Search Icon
```

Placeholder：

```text
搜索邮箱 / 账号...
```

Focus：

```text
Border -> Primary
```

不要做发光 Focus。

---

# 13. Filter / Sort

搜索框右侧增加：

```text
[筛选]
```

或者：

```text
[排序]
```

点击后使用 BottomSheet / PopupMenu。

选项：

```text
全部
可用
未激活
按邮箱名称
按状态
```

如果已有筛选逻辑，保持原逻辑不变，只美化 UI。

---

# 14. 邮箱 Card

每个邮箱 Item：

```text
┌────────────────────────────────────┐
│                                    │
│  A    alice2026                    │
│       ali****@gmail.com            │
│       ● 可用                       │
│                              ✓  ⋮  │
│                                    │
└────────────────────────────────────┘
```

推荐：

```text
Height: 76~88px
Radius: 12px
Padding: 12~16px
```

### Avatar

圆形：

```text
48 x 48
```

颜色使用低饱和浅色。

例如：

```text
A -> Light Blue
B -> Light Green
C -> Light Orange
D -> Light Purple
```

注意：

> Avatar 可以有不同颜色，但整体必须低饱和。

不要使用荧光色。

---

# 15. 邮箱状态

## 可用

```text
● 可用
```

颜色：

```text
Green
```

背景：

```text
Success Soft
```

## 未激活

```text
● 未激活
```

使用：

```text
Gray
```

不要使用大面积灰色背景。

---

# 16. 激活按钮

未激活邮箱显示：

```text
[ ⚡ 激活 ]
```

按钮使用：

```text
Primary
```

但不要渐变。

推荐：

```text
Height 36~40
Radius 8~10
```

点击后：

```text
Loading
↓
激活成功
↓
状态变为「可用」
```

按钮要有轻微点击反馈。

---

# 17. 更多操作

右侧：

```text
⋮
```

点击：

```text
查看详情
复制邮箱
复制账号
重新激活
删除
```

使用：

```text
PopupMenu
```

不要在列表上堆太多按钮。

---

# 18. Bottom Navigation

如果当前项目存在底部导航：

```text
邮箱
激活
我的
```

保持简单。

推荐：

```text
NavigationBar
```

Material 3 当前已经是 Flutter 默认设计体系，NavigationBar 也是 Material 3 对应的导航组件。不要继续使用旧式 Material 2 BottomNavigationBar 视觉。 

当前选中：

```text
Primary
```

未选中：

```text
TextSecondary
```

不要：

- 紫色胶囊
- 大面积渐变
- 发光
- 复杂动画

---

# 19. Empty State

没有邮箱时：

```text
          ✉

      暂无邮箱

导入一个邮箱后，它会显示在这里

       [ 导入邮箱 ]
```

保持极简。

不要使用复杂插画。

---

# 20. Loading

列表加载：

使用：

```text
Skeleton
```

不要直接出现：

```text
CircularProgressIndicator
```

覆盖整个页面。

Skeleton 使用：

```text
#EEF1F5
```

轻微 Shimmer 即可。

---

# 21. Error State

出现错误：

```text
加载失败

请检查网络后重试

[重新加载]
```

Error 使用红色作为状态提示，而不是整个页面变红。

---

# 22. Interaction

所有可点击元素需要有明确反馈：

### Button

```text
Pressed
↓
轻微缩放 / opacity
```

### Card

```text
Pressed
↓
轻微背景变化
```

### List

```text
点击
↓
InkWell / Material ripple
```

不要加入复杂动画。

动画时间：

```text
150~220ms
```

页面切换：

```text
200~300ms
```

目标：

> 有动效，但用户感觉不到“在炫技”。

---

# 23. Dark Mode

Dark Mode 不是简单：

```text
白色 -> 黑色
```

需要重新设计 Surface 层级。

例如：

```text
Background
#0F1115

Card
#171A21

Input
#1D212A

Border
#2A2F38
```

文字：

```text
Primary
#F8FAFC

Secondary
#A1A8B3
```

Primary 使用：

```text
#60A5FA
```

不要紫色。

---

# 24. Flutter 实现要求

优先使用：

```dart
ThemeData
ColorScheme
TextTheme
CardTheme
InputDecorationTheme
ElevatedButtonTheme
OutlinedButtonTheme
NavigationBarTheme
ChipTheme
```

统一管理视觉。

不要在 Widget 里大量出现：

```dart
Colors.xxx
```

应该尽量：

```dart
Theme.of(context).colorScheme.primary
```

或者项目已有 Design Tokens。

Flutter Material 3 当前是默认设计体系，颜色、Typography 和组件主题都应尽量通过 ThemeData / ColorScheme / TextTheme 统一管理。 

---

# 25. 建议建立 Design Tokens

如果项目没有，请创建：

```text
lib/core/theme/
├── app_theme.dart
├── app_colors.dart
├── app_spacing.dart
├── app_radius.dart
└── app_typography.dart
```

例如：

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
```

---

# 26. Widget 拆分

不要把整个首页写成一个巨大 Widget。

建议：

```text
HomePage
├── HomeHeader
├── StatisticsSection
│   ├── MailboxCountCard
│   └── PendingActivationCard
├── MailboxSection
│   ├── MailboxSectionHeader
│   ├── MailboxSearchBar
│   ├── MailboxFilterButton
│   └── MailboxList
│       └── MailboxListItem
└── AppBottomNavigation
```

如果已有类似组件，优先复用。

---

# 27. Responsive

必须兼容：

```text
360px
375px
390px
412px
```

尤其检查：

```text
Header
Statistics Cards
Search
Mailbox Card
Activation Button
Bottom Navigation
```

小屏幕下：

```text
Statistics Cards
```

可以从：

```text
Row
```

变为：

```text
Column
```

如果当前设计在 360px 宽度下容易拥挤，优先保证可读性，而不是强行保持两列。

---

# 28. 最终视觉验收标准

完成后，请自己检查页面。

### 必须达到

- [ ] 不再有大面积紫色
- [ ] 没有 AI 紫色渐变风
- [ ] 没有 Neon Glow
- [ ] 没有过度玻璃拟态
- [ ] 没有夸张圆角
- [ ] 没有明显模板感
- [ ] 信息层级清晰
- [ ] 邮箱列表是视觉重点
- [ ] 状态颜色清晰
- [ ] 激活按钮明显但不过度
- [ ] 页面整体留白充足
- [ ] Typography 清晰
- [ ] Light Mode 高级
- [ ] Dark Mode 高级
- [ ] 小屏幕不溢出
- [ ] 操作反馈自然
- [ ] 没有为了美化破坏现有功能

---

# 29. 最终目标

最终效果不是：

> “哇，好炫，好像 AI 做的。”

而应该是：

> “这看起来像一个已经上线很久、经过设计师打磨的专业工具 App。”

关键词：

```text
Minimal
Premium
Professional
Clean
Quiet
Modern
Reliable
```

---

# 30. Claude Code 执行顺序

请严格按照以下顺序执行：

### Step 1
扫描项目结构。

### Step 2
找到：

- 首页
- Theme
- 公共 Button
- Card
- Input
- Navigation
- 邮箱列表
- 邮箱状态
- 激活逻辑

### Step 3
确认当前 UI 架构。

### Step 4
建立统一 Design Tokens。

### Step 5
重构 Theme。

### Step 6
重构首页布局。

### Step 7
重构 Statistics Card。

### Step 8
重构 Search / Filter。

### Step 9
重构 Mailbox List Item。

### Step 10
重构 Activation Button。

### Step 11
重构 Bottom Navigation。

### Step 12
完善 Dark Mode。

### Step 13
添加轻量交互动画。

### Step 14
运行 Flutter Analyzer。

### Step 15
运行项目并检查 UI。

### Step 16
修复：

- Overflow
- Layout
- Text
- Theme
- Dark Mode
- Interaction

### Step 17
最后再总结修改内容。

---

# 31. 非常重要

不要看到这个 Spec 后重新设计成另一套风格。

**严格按照以下视觉方向执行：**

> 白色 / 浅灰背景 + 白色卡片 + 深色文字 + 单一蓝色品牌色 + 绿色状态色 + 细边框 + 极轻阴影 + 12~16px 圆角 + 大量留白。

**不要使用紫色作为主色。**

**不要使用渐变作为主要视觉元素。**

**不要做成 AI 科技风。**

**不要为了“高级”增加复杂视觉效果。**

高级感来自：

```text
比例
留白
字体
颜色
层级
细节
一致性
```

而不是：

```text
渐变
发光
玻璃
阴影
装饰
```
