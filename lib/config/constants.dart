/// 全局常量配置
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const String appName = '轻康';

  // ═══════════════════════════════════════════════════════════
  // ⚠️ 数据层负责人必改：替换为你的 Gitee 用户名
  // ═══════════════════════════════════════════════════════════
  static const String _giteeUsername = 'souoycn';

  /// Gitee 数据仓库原始文件 URL 前缀
  /// 使用 giteeusercontent.com CDN 加速访问
  /// 文件存放在 data/ 子目录下
  static String get dataRepoBaseUrl =>
      'https://raw.giteeusercontent.com/$_giteeUsername/qk-data/raw/master/data/';

  /// 食物数据 URL（50种食物营养数据）
  static String get foodsUrl => '${dataRepoBaseUrl}foods.json';

  /// 运动数据 URL（10种运动消耗数据）
  static String get sportsUrl => '${dataRepoBaseUrl}sports.json';

  /// 科普文章数据 URL（10~15篇）
  static String get articlesUrl => '${dataRepoBaseUrl}articles.json';

  // ═══════════════════════════════════════════════════════════
  // 预设头像：由角色3（个人中心模块）负责提供实际资源
  // 当前使用 Icons 占位，角色3可替换为 asset 图片或网络头像
  // ═══════════════════════════════════════════════════════════
  static const int presetAvatarCount = 6;

  /// 5种预设习惯
  static const List<Map<String, String>> presetHabits = [
    {'id': 'drink_water', 'name': '喝水8杯', 'icon': '💧'},
    {'id': 'early_sleep', 'name': '早睡', 'icon': '🌙'},
    {'id': 'early_rise', 'name': '早起', 'icon': '🌅'},
    {'id': 'exercise', 'name': '运动', 'icon': '🏃'},
    {'id': 'breakfast', 'name': '吃早餐', 'icon': '🍳'},
  ];
}
