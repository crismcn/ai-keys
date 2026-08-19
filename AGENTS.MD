# AGENTS.MD

本文件是本仓库给 AI 代理（及人类协作者）的**最高优先级工作约定**，覆盖全部代码与文档。技术基调：**技术栈新 · 界面美观 · 高性能 · 轻量化**。

## 1. 项目总览

AI_KEYS：AI 账号 / Key 的自动化工具。

- **后端**：CUN.AI 邮箱验证注册机（Node.js + TypeScript），规格见 [xxx.MD](xxx.MD)，接口细节见 `docs/cun-ai-register-spec.md`。
- **前端**（本仓库新增）：**Flutter 安卓 APP**——注册机的移动端界面，负责触发/查看注册任务、账号与额度管理、运行配置。**APP 是后端的控制端，不是独立注册器**。

### 实现前必读

- [xxx.MD](xxx.MD)：后端完整规格（端点 / 两阶段邮件筛选 / 轮询 / 代理 / 红线）。
- `PRODUCT.MD`：产品定义（当前为空；开发新功能前先在此沉淀产品意图）。
- **文档与代码不一致时以代码为准，并回写文档**（含接口字段变更同步到 specs）。

## 2. 仓库结构

```
AI_KEYS/
├── AGENTS.MD        # 本文件
├── PRODUCT.MD       # 产品定义（待填充）
├── xxx.MD           # 后端注册机规格
├── docs/            # 规格文档（cun-ai-register-spec.md 等）
├── src/             # Node.js 后端（沿用 xxx.MD 的 src/ 布局）
├── app/             # Flutter 安卓 APP（本文档主要规范对象）
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/            # App 装配：theme / router / bootstrap
│   │   ├── core/           # 业务无关：network / constants / utils / design_system
│   │   └── features/       # 按功能分包（feature-first，见 §6）
│   ├── test/  integration_test/
│   ├── android/
│   └── pubspec.yaml  analysis_options.yaml
├── EMAILS.JSON      # 账号池（真实数据，git 忽略）
├── ACCOUNT.MD       # 注册输出（git 忽略）
└── ignore/          # 批量样例数据（git 忽略）
```

> 布局约定：Node 后端保持仓库根（沿用 xxx.MD 路径约定，不改动既有规格）；Flutter APP 固定于 `app/` 子目录，**所有 Flutter 相关命令与文件都以 `app/` 为基准**。

## 3. 技术基线

### 后端（Node，见 xxx.MD）

- Node 18+/20+；TypeScript；npm scripts：`dev` / `build` / `start`。
- 为支撑移动端，后端需在现有 service 层之上**新增 HTTP 控制层**（见 §4 前后端协作）。

### Flutter APP（推荐栈 · 2026 stable）

| 关注点 | 选型 | 说明 |
|---|---|---|
| 版本 | Flutter 最新 stable + Dart 3.x | minSdk ≥ 24；compileSdk/targetSdk 用当前 stable，不追 beta |
| 状态管理 | **Riverpod 3.x**（`riverpod_generator` + `riverpod_annotation`，build_runner 生成） | 现代、可测、按需监听 |
| 路由 | **GoRouter** | stateful shell；统一转场动画 |
| 网络 | **Dio** | 超时 30s、1s/2s/4s/8s 退避重试、请求日志、统一错误映射 |
| 模型 | **Freezed**（不可变数据类/联合类型） | 序列化用 json_serializable 独立标注或手写 fromJson/toJson（**Freezed 3 起不再内置 JSON 生成**） |
| 本地存储 | 会话 token → **flutter_secure_storage**；轻设置 → **shared_preferences** | 确有数据库需求再引入 Hive/Drift，默认不引 |
| 代码生成 | build_runner | 生成文件提交进 git，与手写代码分目录 |
| Lint | `flutter_lints` + 自定义强约束 | 见 §5/§6 |
| 测试 | flutter_test（含 golden）+ integration_test | UI 组件加 golden，关键链路加集成测试 |

### 为什么不用 X（防御性约定）

- 不引 get_it / provider（Riverpod 已含 DI）。
- 不引 Bloc（与 Riverpod 职责重复）。
- 不为「新」而新：**每新增一个 pub 依赖必须回答「它解决了什么、体积/性能/维护代价是多少」**，写进 PR 说明。

## 4. 前后端协作（关键架构约束）

**APP 不持有任何邮箱凭证。** `refresh_token` / `password` / `client_id` 一律只存在于后端（红线 1 同步适用于 APP）。因此：

- 后端新增**轻量 HTTP 服务模式**（复用现有 service 层），提供：
  - 触发/提交注册任务、查看任务队列与状态
  - 账号列表、额度、注册结果
  - 运行配置（并发数、代理、dry-run 开关）
- 注册类动作**默认 DRY-RUN**；真实注册需用户在 APP 显式确认，后端兜底再校验一次。
- API 约定：REST + JSON；统一错误结构 `{ code, message, retryable }`；带鉴权 token；超时与退避对齐后端既有策略。
- 后端 HTTP 接口文档就绪后写回 `docs/`。

## 5. 界面美观（设计原则）

1. **Material 3**；Android 12+ 启用动态取色（`ColorScheme.fromSeed` + `dynamicSchemeVariant`），fallback 品牌色板。
2. 设计 **token 化**：间距 / 圆角 / 阴影 / 字阶集中在 `core/design_system`，禁止散落魔法数；复用组件优先，避免样式漂移。
3. 图标用 Material Symbols；中文用系统字体（字体文件体积见 §7）。
4. 明暗双主题，跟随系统 + 手动切换。
5. 统一路由转场、Hero、骨架屏加载态；**空态 / 加载态 / 错误态三态完备**。
6. **改 UI 必须实际跑起来看效果**（`flutter run`），不能只靠代码推断；改动后截图留档。

## 6. 高性能（红线）

1. `const` 构造优先；避免不必要的 setState / 整树重建。
2. Riverpod 用 `select` 精确监听；页面级才用全局 provider，局部状态用 StatefulWidget / ValueNotifier。
3. 列表一律懒加载（`ListView.builder` / `SliverList`），禁止一次性 build 整页。
4. 长列表 / 图片解码 / JSON 解析等耗时任务放 isolate（`compute`）。
5. 图像按需解码（`cacheWidth`/`cacheHeight`），避免大图整张进内存。
6. 少用 `saveLayer` / 多层 Opacity；动画用隐式动画（AnimatedX / Hero）。
7. 弱网：Dio 超时 + 退避重试；轮询在页面销毁时**必须取消**（协程/订阅），与后端轮询策略对齐。
8. 交付前用 `flutter run --profile` + DevTools 验证关键页面流畅度（无掉帧 / 无重复 rebuild）。

## 7. 轻量化（红线）

1. **发布物只产 arm64-v8a**：`flutter build apk --release --split-per-abi --target-platform android-arm64`；release 启用 R8 压缩 + `--obfuscate --split-debug-info`。
2. **体积目标：release APK（arm64）≤ 15MB；超 20MB 视为回归**，必须说明原因并回退。
3. 禁止引入大体积库（地图、重型图像处理、全套国际化数据等），除非证明必要。
4. 资源：本地图用 WebP / SVG；启用 `shrinkResources`；不捆绑未使用的 Android 插件。
5. 权限最小化：只申请必要权限；不开明文 HTTP（`usesCleartextTraffic=false`）。
6. 发布包不挂 debug keystore；混淆规则不泄露调试信息。

## 8. 工程约定

- **feature-first** 分包：`app/lib/features/<feature>/` 内自含 data / domain / presentation；feature 之间不互相依赖，公共能力下沉 `core/`。
- 提交前 `flutter analyze` 0 error；生成代码与手写代码分离。
- 提交规范：conventional commits（`feat` / `fix` / `refactor` / `perf` / `build` / `docs`…）；开发在 `dev` 分支，稳定后合 `main`。
- 每个功能带测试（unit / widget）；UI 组件加 golden test。
- 改动公共 API / 接口字段：同步回写 [xxx.MD](xxx.MD) 与 `docs/`。

## 9. 常用命令速查

### 后端（仓库根）

- `npm run dev`——单账号 **DRY-RUN**（走完整流程不真实注册）
- `npm run dev -- --live`——单账号真实注册（红线，需确认）
- `npm run dev:batch -- --concurrency 3`——批量（默认 dry-run，`--live` 显式开启）
- `npm test` / `npm run build` / `npm start`

### Flutter（`app/` 目录内）

- `flutter pub get`；`dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`；`flutter test`
- `flutter run`——联机调试；`flutter run --profile`——性能验证
- `flutter build apk --release --split-per-abi --target-platform android-arm64`——轻量发布包
- `flutter build appbundle`——上架 Google Play

## 10. 安全红线（后端 + APP 通用）

1. 严禁在日志、输出、提交内容中出现 `refresh_token`、`password`、邮件正文全文。
2. **真实注册是对外动作**：默认 DRY-RUN，需用户显式确认才执行（APP 内同样有确认步骤）。
3. 所有外部接口必须设超时；可恢复错误按 1s/2s/4s/8s 退避重试，最多 3~5 次。
4. `EMAILS.JSON`、`ignore/`、`.env`、`ACCOUNT.MD` 不得进 git（见 `.gitignore`）。
5. 批量并发限速，避免触发目标平台风控。
6. APP 内不硬编码任何后端 / 邮箱凭据；token 存 secure storage，不落盘明文。

## 11. 代理任务时的标准流程

接到一个任务时按此顺序执行，避免返工：

1. **读文档**：先查 [xxx.MD](xxx.MD) / `PRODUCT.MD` / `docs/` 是否已定义需求与接口；未定义则先补齐文档再动手。
2. **定影响面**：后端（`src/`）还是前端（`app/`），或跨端接口；跨端必须先在 §4 约定的 API 结构上对齐。
3. **实现**：遵循 §5~§7 原则；新增依赖先自问体积/性能代价。
4. **验证**：后端 `npm test`；前端 `flutter analyze` + `flutter test` + `flutter run` 实机看效果。
5. **回写**：接口字段或行为变更同步回写 specs 与本文档相关小节。
