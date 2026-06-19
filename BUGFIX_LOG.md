# 「轻康」开发过程中遇到的困难与解决方案

> 记录项目集成阶段发现的Bug、功能缺口及修复过程，供实验报告参考。

---

## 1. Hero 标签冲突导致应用崩溃

**现象**：应用启动后立即抛出异常 `There are multiple heroes that share the same tag within a subtree`，无法正常使用。

**原因**：`MainShell` 使用 `IndexedStack` 保持所有Tab页面同时存活，而 `exercise_page.dart` 和 `diet_page.dart`（及其他子页面）的 `FloatingActionButton` 均未指定 `heroTag`，导致 Flutter 的 Hero 动画系统检测到多个默认标签冲突。

**解决方案**：为每个 `FloatingActionButton` 添加唯一 `heroTag`。

**修改文件**：
| 文件 | 改动 |
|------|------|
| `lib/pages/exercise/exercise_page.dart` | FAB 添加 `heroTag: 'exercise_add'` |
| `lib/pages/exercise/exercise_history_page.dart` | FAB 添加 `heroTag: 'exercise_history_add'` |
| `lib/pages/diet/diet_page.dart` | FAB 添加 `heroTag: 'diet_add'` |
| `lib/pages/diet/diet_today_page.dart` | FAB 添加 `heroTag: 'diet_today_add'` |

**经验总结**：在 `IndexedStack` 中使用 `FloatingActionButton` 时必须显式指定 `heroTag`，否则所有同时存活的页面会共享默认标签导致冲突。

---

## 2. 数据变更后其他页面不刷新

**现象**：在运动/饮食/习惯模块添加或删除记录后，返回首页或切换到其他Tab，卡路里数据和习惯进度不会自动更新，必须手动下拉刷新。

**原因**：各模块的 Service 层只有数据读写功能，没有通知机制。首页和各模块首页在 `initState` 中加载数据后，不会因其他页面的数据变更而重新加载。

**解决方案**：采用轻量的事件通知机制——
1. 在 `ExerciseService`、`DietService`、`HabitStorageUtil` 中各添加一个 `static final ValueNotifier<int> changeNotifier`
2. 每次 `addRecord` / `deleteRecord` / `toggleHabit` 等修改操作后执行 `changeNotifier.value++`
3. 首页和各模块首页在 `initState` 中 `addListener`，监听变化后自动调用数据刷新方法

**修改文件**：
| 文件 | 改动 |
|------|------|
| `lib/services/exercise_service.dart` | 添加 `changeNotifier`，增删记录时触发 |
| `lib/services/diet_service.dart` | 添加 `changeNotifier`，增删记录时触发 |
| `lib/services/habit_storage_util.dart` | 添加 `changeNotifier`，打卡切换时触发 |
| `lib/pages/home/home_page.dart` | 监听三个 notifier，数据变更自动刷新 |
| `lib/pages/exercise/exercise_page.dart` | 监听运动 notifier |
| `lib/pages/diet/diet_page.dart` | 监听饮食 notifier |

**经验总结**：在无状态管理框架的轻量项目中，`ValueNotifier` + `addListener` 是一种零依赖、极简的跨页面通信方案。

---

## 3. 健康目标设置后无反馈

**现象**：用户在「个人中心 → 健康目标设置」中设定了每日运动时长和卡路里摄入目标，但首页和任何页面都没有展示目标值或完成进度，目标功能形同虚设。

**原因**：`goal_setting.dart` 通过 `StorageUtil` 存储了 `goal_exercise_duration` 和 `goal_calorie_intake`，但全项目没有任何地方读取这两个值。

**解决方案**：在首页 `_loadUserData` 中读取目标值，并在卡路里概览卡片中展示目标对比文字（如「目标 30min」「目标 2000 kcal」）。

**修改文件**：
| 文件 | 改动 |
|------|------|
| `lib/pages/home/home_page.dart` | `_loadUserData` 中读取目标存储值；`_buildKcalCard` 新增可选 `goal` 参数，在标签行右侧显示目标 |

**经验总结**：数据存入后必须有对应的读取和展示路径，否则就是死数据。功能闭环 = 设置 → 存储 → 读取 → 展示。

---

## 4. 首页科普推荐为硬编码假数据

**现象**：首页底部的「今日推荐」科普卡片始终显示固定的标题和摘要，无论远程科普文章库如何更新都不会变化，不满足「数据100%远程加载」的要求。

**原因**：首页的 `_todayArticle` 是一个写死的 `Map<String, String>`。

**解决方案**：引入 `ArticleRepository`，在 `_loadUserData` 中异步加载远程文章列表，随机选取一篇展示。点击卡片跳转到文章详情页而非列表页，体验更直接。

**修改文件**：
| 文件 | 改动 |
|------|------|
| `lib/pages/home/home_page.dart` | 添加 `ArticleRepository` 和 `Article` 模型引用；`_todayArticle` 改为 `Article?` 类型；`_loadUserData` 中远程加载并随机选取；`_buildArticleCard` 点击跳转到详情页 |

---

## 5. 手机端底部溢出

**现象**：在手机设备上，运动模块首页和饮食模块首页底部出现 `BOTTOM OVERFLOWED BY 12 PIXELS` 的布局溢出警告。

**原因**：两个页面的布局完全相同——顶部热量卡片 + GridView（2列2行，`childAspectRatio: 1.2`）+ 底部小贴士卡片 + FAB，在小屏手机上累计高度超出屏幕可用空间。

**解决方案**：通过微调多个间距参数在不影响视觉效果的前提下压缩总高度约60px：

| 参数 | 修改前 | 修改后 |
|------|--------|--------|
| GridView `childAspectRatio` | 1.2 | 1.1 |
| GridView 间距 | 12 | 10 |
| 顶部卡片垂直 padding | 20 | 16 |
| 小贴士卡片 padding | 16 | 12 |
| 各段间距 | 16 | 12 / 10 |

**修改文件**：
| 文件 | 改动 |
|------|------|
| `lib/pages/diet/diet_page.dart` | 调整 GridView、卡片、间距参数 |
| `lib/pages/exercise/exercise_page.dart` | 同饮食模块，同步调整 |

**经验总结**：`IndexedStack` + 多内容页面的场景下，应在开发阶段就用小屏模拟器测试，避免集成后才发现溢出。

---

## 6. 遗留占位文件未清理

**现象**：`knowledge_placeholder.dart` 和 `profile_placeholder.dart` 在路由中已被真实页面替换，但文件仍残留在磁盘上，成为死代码。

**解决方案**：直接删除两个文件。

**修改文件**：
| 文件 | 操作 |
|------|------|
| `lib/pages/knowledge/knowledge_placeholder.dart` | 删除 |
| `lib/pages/profile/profile_placeholder.dart` | 删除 |

---

## 7. PR合并后源文件全部位于根目录，Flutter不编译

**现象**：角色4完成运动打卡模块开发并提交PR合并后，本地运行App完全看不到任何运动相关功能。Git记录显示1608行代码已合并成功，但App行为毫无变化。

**原因**：PR中所有11个 `.dart` 源文件被放在了项目根目录（与 `pubspec.yaml` 同级），而Flutter只会编译 `lib/` 目录下的Dart文件。根目录的Dart文件对Flutter完全透明。

**排查过程**：
1. `git fetch` + `git status -sb` 确认本地与远程同步
2. `git show --stat <merge-commit>` 发现11个文件均位于根目录
3. `git ls-tree -r HEAD` 对比发现 `lib/` 下没有对应文件

**解决方案**：将11个文件手动迁移至 `lib/` 对应位置，4个冲突文件以PR版本覆盖原有文件：

| 文件 | 迁移目标 | 冲突处理 |
|------|---------|---------|
| `app.dart` | → `lib/app.dart` | 覆盖（PR版：接入真实运动页面） |
| `home_page.dart` | → `lib/pages/home/home_page.dart` | 覆盖（PR版：接入ExerciseService） |
| `sport.dart` | → `lib/models/sport.dart` | 覆盖（PR版：增加==/hashCode） |
| `sport_repository.dart` | → `lib/repository/sport_repository.dart` | 覆盖（PR版：增加异常兜底） |
| `exercise_page.dart` | → `lib/pages/exercise/exercise_page.dart` | 新增 |
| `exercise_add_page.dart` | → `lib/pages/exercise/exercise_add_page.dart` | 新增 |
| `exercise_history_page.dart` | → `lib/pages/exercise/exercise_history_page.dart` | 新增 |
| `exercise_stats_page.dart` | → `lib/pages/exercise/exercise_stats_page.dart` | 新增 |
| `exercise_record.dart` | → `lib/models/exercise_record.dart` | 新增 |
| `exercise_service.dart` | → `lib/services/exercise_service.dart` | 新增 |
| `mock_data.dart` | → `lib/data/mock_data.dart` | 新增 |

迁移后执行 `flutter analyze` 验证：0个编译错误，13个代码风格建议（info级别，不影响编译）。

**经验总结**：
- Flutter项目的**所有Dart源码必须位于 `lib/` 目录**，根目录仅放 `pubspec.yaml`、`README.md` 等配置文件
- PR合并后应立即 `flutter run` 验证功能是否生效，不能仅看Git合并状态
- 需在团队规范中明确文件目录约束，后续在 `README.md` 中标注了每个目录的归属

---

## 8. 远程数据加载失败 —— Gitee Raw接口与Dio类型系统不兼容

**现象**：回退 mock_data 兜底后，运动类型下拉框变为空，控制台报错：
```
HttpUtil.getList error: DioException [unknown]: null
Error: type 'String' is not a subtype of type 'List<dynamic>?' in type cast
```
修复第一轮后继续报错：
```
HttpUtil.getList error: FormatException: Unexpected character (at character 1)
```

**原因链**：
1. **Content-Type 不匹配**：Gitee Raw 接口返回 `Content-Type: text/plain`，Dio 默认不会对非 `application/json` 响应自动解析JSON
2. **泛型类型强转失败**：`_dio.get<List<dynamic>>()` 期望响应体已是 `List` 类型，但实际得到的是原始字符串，类型转换抛出异常
3. **UTF-8 BOM头干扰**：修复第一步后改为 `get<String>` + `jsonDecode`，但 Gitee 响应的 UTF-8 BOM (`\uFEFF`) 导致 `jsonDecode` 抛出 `FormatException`

**解决方案（三轮迭代）**：

| 轮次 | 尝试 | 结果 |
|------|------|------|
| 1 | 加 `responseType: ResponseType.json` | ❌ 无效，Dio泛型类型强转仍失败 |
| 2 | `get<String>` + `jsonDecode` | ❌ BOM头导致FormatException |
| 3 | `get<String>` + `ResponseType.plain` + BOM剥离 + `jsonDecode` | ✅ 成功 |

最终版 `HttpUtil.getList` 核心逻辑：
```dart
final response = await _dio.get<String>(
  url,
  options: Options(responseType: ResponseType.plain),
);
var body = response.data!;
if (body.codeUnitAt(0) == 0xFEFF) { body = body.substring(1); }
final decoded = jsonDecode(body);
if (decoded is List) return decoded;
```

同时将 Gitee URL 从 CDN 域名 `raw.giteeusercontent.com` 切换为标准格式 `gitee.com/<user>/<repo>/raw/<branch>/data/`，避免部分网络环境CDN不可达。

**修改文件**：
| 文件 | 改动 |
|------|------|
| `lib/services/http_util.dart` | 重写 `getList` 和 `getMap`：`ResponseType.plain` + 手动 `jsonDecode` + BOM剥离 |
| `lib/config/constants.dart` | URL前缀从 `raw.giteeusercontent.com` 改为 `gitee.com/.../raw/...` |

**经验总结**：
- 不要信任第三方接口的 Content-Type 声明，用 `ResponseType.plain` 获取原始字符串再手动解析是更稳健的策略
- Dart 的 `jsonDecode` 不会自动处理 BOM，需手动剥离
- mock_data 兜底会掩盖网络层的真实问题，导致问题在集成阶段才暴露

---

## 9. 角色4跨模块越界修改

**现象**：角色4在提交运动打卡模块时，额外修改了角色2的两个文件：
- `lib/models/sport.dart` — 添加了 `==` 和 `hashCode` 重载
- `lib/repository/sport_repository.dart` — 添加了 `mock_data.dart` 导入和 try-catch 兜底逻辑

**影响**：
- `sport.dart` 的改动为纯增强（相等性比较），无副作用
- `sport_repository.dart` 的改动改变了错误处理行为，且 mock_data 兜底掩盖了 HttpUtil 的远程加载Bug（见第8条），导致问题在回退后才暴露

**解决方案**：
1. 保留 `sport.dart` 的 `==`/`hashCode` 改动（有益且无害）
2. 回退 `sport_repository.dart` 至角色2原版，远程加载已修复后不再需要 mock_data 兜底
3. 同时清理根目录残留的 `exercise_add_page.dart`、`exercise_history_page.dart` 和废弃的 `exercise_placeholder.dart`

**修改文件**：
| 文件 | 操作 |
|------|------|
| `lib/repository/sport_repository.dart` | 回退至角色2原版 |
| `lib/models/sport.dart` | 保留PR版（含==/hashCode），后续测试通过后回退 |
| `lib/pages/exercise/exercise_placeholder.dart` | 删除（已无引用） |
| 根目录 `exercise_add_page.dart` | 删除（残留副本） |
| 根目录 `exercise_history_page.dart` | 删除（残留副本） |

**经验总结**：
- 严格按照方案文档的分工边界开发，**不碰他人模块文件**是多人协作的基本纪律
- 发现公共层有问题时应反馈给组长修复，而非在业务层加兜底绕过
- 兜底逻辑（fallback/mock）会掩盖真实Bug，延误修复时机

---

## 总结

以上9个问题的修复覆盖了**运行时崩溃、数据流断裂、功能闭环缺失、网络数据合规、多屏适配、代码卫生、文件目录规范、网络层兼容性、团队协作边界**九个维度，使得项目从"各模块代码存在"提升到"全功能可正常运行"的交付标准。

**团队规范核心要点**（根据踩坑提炼）：
1. 所有Dart源码必须放在 `lib/` 目录对应子目录下
2. 禁止跨模块修改他人代码
3. PR前先同步main分支，跑通 `flutter analyze`

---

## 10. Android端网络请求失败——缺少权限与安全配置

**现象**：之前手机安装后可以正常加载远程数据（运动列表、食物列表、科普文章），但现在打开后所有需要联网的页面都显示空数据，远程数据完全获取不到。PC端浏览器/curl访问同一URL正常返回200。

**原因**：
1. **AndroidManifest.xml 缺少 `INTERNET` 权限声明** — 虽然 Google 文档声明 INTERNET 是"普通权限"会自动授予，但在国产手机系统（MIUI、ColorOS、EMUI、HarmonyOS 等）上，缺少显式声明会导致系统拦截网络请求
2. **缺少网络安全配置** — 随着 Flutter SDK 升级，`targetSdkVersion` 可能升高，Android 9+ 对 HTTPS 证书链验证更严格，没有 `network_security_config.xml` 显式信任 Gitee 域名可能导致 SSL 握手失败
3. **无本地兜底数据** — 即使远程加载失败，App 也应有本地 Mock 数据保证基本功能可用，而不是完全白屏

**解决方案**：

| 修复项 | 内容 |
|--------|------|
| 添加网络权限 | `AndroidManifest.xml` 中添加 `<uses-permission android:name="android.permission.INTERNET"/>` |
| 开启明文流量 | `application` 标签添加 `android:usesCleartextTraffic="true"` |
| 网络安全配置 | 新建 `res/xml/network_security_config.xml`，信任系统证书并显式放行 `gitee.com` 和 `giteeusercontent.com` 域名 |
| 本地兜底数据 | `MockData` 扩充为包含运动、食物、文章三类兜底数据；三个 Repository 在网络请求返回空时自动降级使用 MockData |

**修改文件**：
| 文件 | 改动 |
|------|------|
| `android/app/src/main/AndroidManifest.xml` | 添加 INTERNET 权限 + `usesCleartextTraffic` + `networkSecurityConfig` |
| `android/app/src/main/res/xml/network_security_config.xml` | 新建，配置系统证书信任及 Gitee 域名白名单 |
| `lib/data/mock_data.dart` | 扩充，新增 `foods` 和 `articles` 静态兜底数据 |
| `lib/repository/sport_repository.dart` | 远程返回空时降级 `MockData.sports` |
| `lib/repository/food_repository.dart` | 远程返回空时降级 `MockData.foods` |
| `lib/repository/article_repository.dart` | 远程返回空时降级 `MockData.articles` |

**经验总结**：
- Android 网络问题优先检查 `AndroidManifest.xml` 中的权限声明和 `network_security_config.xml`
- 国产 ROM 对权限管控比原生 Android 更严格，不能仅依赖 Google 文档
- 远程数据加载必须有本地兜底，保证弱网/无网环境下 App 基本功能可用
- `BaseOptions` 中的 `connectTimeout` 和 `receiveTimeout` 是网络请求的最后防线
4. 不要用 mock 数据掩盖真实问题
5. 网络层使用 `ResponseType.plain` + 手动解析，不信任第三方 Content-Type
