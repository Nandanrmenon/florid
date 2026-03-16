// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_name => 'Florid';

  @override
  String get welcome => '欢迎使用 Florid';

  @override
  String get search => '搜索';

  @override
  String get settings => '设置';

  @override
  String get home => '主页';

  @override
  String get categories => '分类';

  @override
  String get updates => '更新';

  @override
  String get installed => '已安装';

  @override
  String get download => '下载';

  @override
  String get install => '安装';

  @override
  String get uninstall => '卸载';

  @override
  String get open => '启动';

  @override
  String get cancel => '取消';

  @override
  String get update_available => '可用更新';

  @override
  String get downloading => '下载中……';

  @override
  String get install_permission_required => '安装权限要求';

  @override
  String get storage_permission_required => '需要存储权限';

  @override
  String get cancel_download => '取消下载';

  @override
  String get version => '版本';

  @override
  String get size => '大小';

  @override
  String get description => '描述';

  @override
  String get permissions => '权限';

  @override
  String get screenshots => '屏幕截图';

  @override
  String get no_version_available => '无可用版本';

  @override
  String get app_information => '应用信息';

  @override
  String get package_name => '包名';

  @override
  String get license => '协议';

  @override
  String get added => '额外';

  @override
  String get last_updated => '最后更新';

  @override
  String get version_information => '版本信息';

  @override
  String get version_name => '版本名称';

  @override
  String get version_code => '版本代码';

  @override
  String get min_sdk => '最小 SDK';

  @override
  String get target_sdk => '目标 SDK';

  @override
  String get all_versions => '所以版本';

  @override
  String get latest => '最新';

  @override
  String get released => '发行版';

  @override
  String get loading => '加载中……';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get share => '分享';

  @override
  String get website => '网站';

  @override
  String get source_code => '源代码';

  @override
  String get issue_tracker => '问题追踪器';

  @override
  String get whats_new => '最新动态';

  @override
  String get show_more => '显示更多';

  @override
  String get show_less => '显示更少';

  @override
  String get downloads_stats => '下载统计';

  @override
  String get last_day => '最近一天';

  @override
  String get last_30_days => '近30天';

  @override
  String get last_365_days => '近365天';

  @override
  String get not_available => '不可用';

  @override
  String get download_failed => '下载失败';

  @override
  String get installation_failed => '安装失败';

  @override
  String get uninstall_failed => '卸载失败';

  @override
  String get open_failed => '启动失败';

  @override
  String get device => '本地';

  @override
  String get recently_updated => '最近更新';

  @override
  String get refresh => '刷新';

  @override
  String get about => '关于';

  @override
  String get refreshing_data => '刷新数据中……';

  @override
  String get data_refreshed => '数据已刷新';

  @override
  String get refresh_failed => '刷新失败';

  @override
  String get loading_latest_apps => '加载最新应用中……';

  @override
  String get latest_apps => '最新应用';

  @override
  String get no_apps_found => '未找到应用';

  @override
  String get searching => '搜索中……';

  @override
  String get setup_failed => '配置失败';

  @override
  String get back => '返回';

  @override
  String get allow => '允许';

  @override
  String get manage_repositories => '管理存储库';

  @override
  String get enable_disable => '启用/禁用';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get delete_repository => '删除存储库';

  @override
  String delete_repository_confirm(Object name, Object repository) {
    return '确定要移除“$name”吗？';
  }

  @override
  String get updating_repository => '正在更新存储库';

  @override
  String get touch_grass_message => '现在是摸草的好时机！';

  @override
  String get add_repository => '添加存储库';

  @override
  String get add => '添加';

  @override
  String get save => '保存';

  @override
  String get enter_repository_name => '请输入一个存储库名称';

  @override
  String get enter_repository_url => '请输入一个存储库链接';

  @override
  String get edit_repository => '编辑存储库';

  @override
  String get loading_apps => '正在加载应用……';

  @override
  String no_apps_in_category(Object category) {
    return '$category 分类下没有应用';
  }

  @override
  String get loading_categories => '加载分类中……';

  @override
  String get no_categories_found => '无分类';

  @override
  String get on_device => '此设备';

  @override
  String get favourites => '收藏';

  @override
  String get loading_repository => '加载存储库…';

  @override
  String get unable_to_load_repository => '无法加载存储库';

  @override
  String get repository_loading_error_descrption => '请检查您的网络连接或存储库设置，然后重试。';

  @override
  String get appUpdateAvailable => '可用更新';

  @override
  String get releaseNotes => '发行版记录';

  @override
  String get dismiss => '忽略';

  @override
  String get viewOnGithub => '在 GitHub 中查看';

  @override
  String get update => '更新';

  @override
  String get installing => '安装中……';

  @override
  String get downloadFailed => 'APK 下载失败';

  @override
  String get remove_from_favourites => '取消收藏';

  @override
  String get add_to_favourites => '添加收藏';

  @override
  String get view_details => '查看详情';

  @override
  String installation_started(Object appName) {
    return '$appName 开始安装！';
  }

  @override
  String installation_failed_with_error(Object error) {
    return '安装失败：$error';
  }

  @override
  String download_started(Object appName) {
    return '$appName 开始下载！';
  }

  @override
  String download_failed_with_error(Object error) {
    return '下载失败：$error';
  }

  @override
  String get start_setup => '开始设置';

  @override
  String get continue_text => '继续';

  @override
  String get loading_changelog => '加载更新日志中……';

  @override
  String get appearance => '外观';

  @override
  String get theme_mode => '主题';

  @override
  String get follow_system_theme => '跟随系统设置';

  @override
  String get light_theme => '浅色主题';

  @override
  String get dark_theme => '暗色主题';

  @override
  String get dynamic_color => '动态颜色';

  @override
  String get material_you_dynamic => 'Material You Dynamic';

  @override
  String get use_system_colors_supported_android => '使用系统支持的颜色';

  @override
  String get theme_style => '主题样式';

  @override
  String get material_style => 'Material 样式';

  @override
  String get dark_knight => 'Dark Knight';

  @override
  String get dark_knight_subtitle => '深色、高对比度的Florid启发主题';

  @override
  String get florid_style => 'Florid 样式';

  @override
  String get beta => 'Beta';

  @override
  String get other => '其他';

  @override
  String get show_whats_new => '查看最新内容';

  @override
  String get show_monthly_top_apps => 'Show Monthly Top Apps';

  @override
  String get feedback_on_florid_theme => '反馈Florid主题';

  @override
  String get help_improve_florid_theme_feedback => '通过提供反馈帮助改善Florid的主题';

  @override
  String get system_installer => '系统安装程序';

  @override
  String get shizuku => 'Shizuku';

  @override
  String get installation_method => '安装方式';

  @override
  String get requires_shizuku_running => '需要Shizuku运行';

  @override
  String get uses_standard_system_installer => '使用标准系统安装程序';

  @override
  String get open_shizuku => '打开 Shizuku';

  @override
  String get use_system_installer => '使用系统安装程序';

  @override
  String get close => '关闭';

  @override
  String get wifi_only => '仅无线网络';

  @override
  String get wifi_and_charging => '无线网络且充电状态下';

  @override
  String get mobile_data_or_wifi => '移动数据或无线网络';

  @override
  String get every_1_hour => '每1小时';

  @override
  String get every_2_hours => '每2小时';

  @override
  String get every_3_hours => '每3小时';

  @override
  String get every_6_hours => '每6小时';

  @override
  String get every_12_hours => '每12小时';

  @override
  String get daily => '每日';

  @override
  String every_hours(int hours) {
    return '每$hours小时';
  }

  @override
  String get update_network => '更新网络';

  @override
  String get update_interval => '更新间隔';

  @override
  String get app_management => '应用管理';

  @override
  String get alpha => 'Alpha';

  @override
  String get downloads_and_storage => '下载 & 存储';

  @override
  String get auto_install_after_download => '下载后自动安装';

  @override
  String get auto_install_after_download_subtitle => '下载完成后自动安装 APK';

  @override
  String get delete_apk_after_install => '安装后删除 APK';

  @override
  String get delete_apk_after_install_subtitle => '成功安装后删除安装程序文件';

  @override
  String get background_updates => '后台更新';

  @override
  String get check_updates_in_background => '在后台检查更新';

  @override
  String get notify_when_updates_available => '更新可用时通知';

  @override
  String get reliability => '可用性';

  @override
  String get disable_battery_optimization => '禁用电池优化';

  @override
  String get allow_background_checks_reliably => '允许后台检查可用性';

  @override
  String get run_debug_check_10s => '运行10秒的调试检查';

  @override
  String get run_debug_check_10s_subtitle => '显示测试通知并在10秒后运行';

  @override
  String get debug_check_scheduled => '已排程侦错检查';

  @override
  String get debug_update_check_runs_10s => '侦错更新检查将在10秒后执行';

  @override
  String get no_recently_updated_apps => '无最近更新的应用程序';

  @override
  String get no_new_apps => '无新应用';

  @override
  String get monthly_top_apps => '月度热门应用';

  @override
  String get from_izzyondroid => '来自 IzzyOnDroid';

  @override
  String get sync_required => '需要同步';

  @override
  String get izzyondroid_sync_required_message =>
      '需要同步 IzzyOnDroid 存储库以显示热门应用程序。';

  @override
  String get go_to_settings => '前往设置';

  @override
  String get keep_android_open => '保持 Android 开放';

  @override
  String get keep_android_open_message =>
      '从 2026/2027 年开始，谷歌将要求所有在认证设备上安装的 Android 应用（包括从 Play 商店之外安装的应用）都必须经过开发者验证。';

  @override
  String get ignore => '忽略';

  @override
  String get learn_more => '了解更多';

  @override
  String get search_fdroid_apps => '搜索 F-Droid 应用……';

  @override
  String get filters => '筛选';

  @override
  String get search_apps => '搜索应用';

  @override
  String get search_failed => '搜索失败';

  @override
  String get unknown_error_occurred => '发生未知错误';

  @override
  String get try_different_keywords => '尝试不同的关键字或检查拼写';

  @override
  String get popular_searches => '热门搜索：';

  @override
  String get clear_all => '清除所有';

  @override
  String get sort_by => '排序';

  @override
  String get relevance => '关系程度';

  @override
  String get name_az => '名称(A-Z)';

  @override
  String get name_za => '名称(Z-A)';

  @override
  String get recently_added => '最近添加';

  @override
  String get no_categories_available => '无分类可用';

  @override
  String get repositories => '存储库';

  @override
  String get apply_filters => '应用筛选';

  @override
  String search_results_for_query(int count, Object query) {
    return '找到 $count 条关于 “$query” 的结果';
  }

  @override
  String get loading_top_apps => '正在加载热门应用……';

  @override
  String get failed_to_load_apps => '加载应用失败';

  @override
  String get try_again => '重试';

  @override
  String get no_apps_from_izzyondroid => '没有来自 IzzyOnDroid 的应用';

  @override
  String get no_favourites_yet => '无收藏应用';

  @override
  String get tap_star_to_save => '点击星形以将其保存在此处';

  @override
  String update_failed_with_error(Object error) {
    return '更新失败：$error';
  }

  @override
  String get user => '用户';

  @override
  String auto_install_failed_with_error(Object error) {
    return '自动安装失败：$error';
  }

  @override
  String installing_app(Object appName) {
    return '安装 $appName 中……';
  }

  @override
  String get install_from_repository => '从存储库安装';

  @override
  String get download_from_repository => '从存储库下载';

  @override
  String choose_repository_for_action(Object action) {
    return '你可以选择使用哪个仓库来$action这个应用。';
  }

  @override
  String get unknown => '未知';

  @override
  String previously_installed_from(Object repositoryName) {
    return '此前安装来源：$repositoryName';
  }

  @override
  String get previously_installed_from_here => '以前从此处安装';

  @override
  String get default_repository => '默认';

  @override
  String by_author(Object author) {
    return '来自 $author';
  }

  @override
  String check_out_on_fdroid(Object appName, Object packageName) {
    return '在 F-Droid 上查看 $appName：https://f-droid.org/packages/$packageName/';
  }

  @override
  String get rebuild_repositories => '重建存储库';

  @override
  String get preset => '预设';

  @override
  String get your_repositories => '你的存储库';

  @override
  String get no_custom_repositories => '未添加自定义存储库';

  @override
  String get add_custom_repository_to_start => '添加自定义 F-Droid 源以开始';

  @override
  String get scan => '扫描';

  @override
  String get point_camera_qr => '将镜头对准二维码';

  @override
  String get tap_keyboard_enter_url => '点击键盘输入 URL';

  @override
  String get loading_repository_configuration => '加载存储库配置中……';

  @override
  String get adding_selected_repositories => '正在导入选中的存储库……';

  @override
  String get fetching_fdroid_repository_index => '正在同步 F-Droid 仓库索引……';

  @override
  String get importing_apps_to_database => '正在将应用导入数据库……';

  @override
  String importing_apps_to_database_seconds(int seconds) {
    return '正在将应用导入数据库...（$seconds 秒）';
  }

  @override
  String get loading_custom_repositories => '正在加载自定义存储库……';

  @override
  String get setup_complete => '已配置完成！';

  @override
  String get welcome_to => '欢迎使用';

  @override
  String get onboarding_intro_subtitle =>
      '一款现代 F-Droid 客户端，让你轻松浏览、搜索和下载开源 Android 应用。';

  @override
  String get curated_open_source_apps => '精选开源应用';

  @override
  String get safe_downloads => '保存下载';

  @override
  String get updates_and_notifications => '更新 & 通知';

  @override
  String get add_extra_repositories => '添加额外存储库';

  @override
  String get repos_step_description =>
      'Florid 预装了官方 F-Droid 软件源。您还可以添加可信的社区软件源来获取更多应用。';

  @override
  String get available_repositories => '可用存储库';

  @override
  String get manage_repositories_anytime => '您可以在“设置”中随时添加或删除存储库。';

  @override
  String get request_permissions => '请求权限';

  @override
  String get permissions_step_description => 'Florid 需要一些权限才能为您提供最佳体验。';

  @override
  String get notifications => '通知';

  @override
  String get get_notified_updates => '应用更新时收到通知';

  @override
  String get app_installation => '应用安装';

  @override
  String get allow_florid_install_apps => '允许 Florid 安装下载的应用';

  @override
  String get enable_permissions_anytime => '您可以随时在设置中启用这些权限。';

  @override
  String get setting_up_florid => '配置 Florid';

  @override
  String get no_antifeature_listed => '未列出反特性';

  @override
  String get open_link => '打开链接';

  @override
  String get loading_recently_updated_apps => '加载最近更新的应用程序……';

  @override
  String get checking_for_updates => '检查更新中';

  @override
  String get import_favourites => '导入收藏夹';

  @override
  String get merge => '合并';

  @override
  String get update_all => '更新所有';

  @override
  String get apps => '应用';

  @override
  String get troubleshooting => '故障排除';

  @override
  String get replace => '替换';

  @override
  String get your_name => '你的昵称';

  @override
  String get enter_your_name => '输入你的昵称';

  @override
  String get top_apps => 'Top Apps';

  @override
  String get games => 'Games';

  @override
  String get auth_all_apps => 'All Apps';

  @override
  String get auth_all_apps_desc =>
      'Require authentication for all installations';

  @override
  String get auth_all_apps_w_anti_feat => 'Apps with Anti-Features';

  @override
  String get auth_all_apps_w_anti_feat_desc =>
      'Require authentication only for apps that have anti-features.';

  @override
  String get support_the_developer => 'Support the Developer';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get app_name => 'Florid';

  @override
  String get welcome => '欢迎使用 Florid';

  @override
  String get search => '搜索';

  @override
  String get settings => '设置';

  @override
  String get home => '主页';

  @override
  String get categories => '分类';

  @override
  String get updates => '更新';

  @override
  String get installed => '已安装';

  @override
  String get download => '下载';

  @override
  String get install => '安装';

  @override
  String get uninstall => '卸载';

  @override
  String get open => '启动';

  @override
  String get cancel => '取消';

  @override
  String get update_available => '可用更新';

  @override
  String get downloading => '下载中……';

  @override
  String get install_permission_required => '安装权限要求';

  @override
  String get storage_permission_required => '需要存储权限';

  @override
  String get cancel_download => '取消下载';

  @override
  String get version => '版本';

  @override
  String get size => '大小';

  @override
  String get description => '描述';

  @override
  String get permissions => '权限';

  @override
  String get screenshots => '屏幕截图';

  @override
  String get no_version_available => '无可用版本';

  @override
  String get app_information => '应用信息';

  @override
  String get package_name => '包名';

  @override
  String get license => '协议';

  @override
  String get added => '额外';

  @override
  String get last_updated => '最后更新';

  @override
  String get version_information => '版本信息';

  @override
  String get version_name => '版本名称';

  @override
  String get version_code => '版本代码';

  @override
  String get min_sdk => '最小 SDK';

  @override
  String get target_sdk => '目标 SDK';

  @override
  String get all_versions => '所以版本';

  @override
  String get latest => '最新';

  @override
  String get released => '发行版';

  @override
  String get loading => '加载中……';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get share => '分享';

  @override
  String get website => '网站';

  @override
  String get source_code => '源代码';

  @override
  String get issue_tracker => '问题追踪器';

  @override
  String get whats_new => '最新动态';

  @override
  String get show_more => '显示更多';

  @override
  String get show_less => '显示更少';

  @override
  String get downloads_stats => '下载统计';

  @override
  String get last_day => '最近一天';

  @override
  String get last_30_days => '近30天';

  @override
  String get last_365_days => '近365天';

  @override
  String get not_available => '不可用';

  @override
  String get download_failed => '下载失败';

  @override
  String get installation_failed => '安装失败';

  @override
  String get uninstall_failed => '卸载失败';

  @override
  String get open_failed => '启动失败';

  @override
  String get device => '本地';

  @override
  String get recently_updated => '最近更新';

  @override
  String get refresh => '刷新';

  @override
  String get about => '关于';

  @override
  String get refreshing_data => '刷新数据中……';

  @override
  String get data_refreshed => '数据已刷新';

  @override
  String get refresh_failed => '刷新失败';

  @override
  String get loading_latest_apps => '加载最新应用中……';

  @override
  String get latest_apps => '最新应用';

  @override
  String get no_apps_found => '未找到应用';

  @override
  String get searching => '搜索中……';

  @override
  String get setup_failed => '配置失败';

  @override
  String get back => '返回';

  @override
  String get allow => '允许';

  @override
  String get manage_repositories => '管理存储库';

  @override
  String get enable_disable => '启用/禁用';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get delete_repository => '删除存储库';

  @override
  String delete_repository_confirm(Object name, Object repository) {
    return '确定要移除“$name”吗？';
  }

  @override
  String get updating_repository => '正在更新存储库';

  @override
  String get touch_grass_message => '现在是摸草的好时机！';

  @override
  String get add_repository => '添加存储库';

  @override
  String get add => '添加';

  @override
  String get save => '保存';

  @override
  String get enter_repository_name => '请输入一个存储库名称';

  @override
  String get enter_repository_url => '请输入一个存储库链接';

  @override
  String get edit_repository => '编辑存储库';

  @override
  String get loading_apps => '正在加载应用……';

  @override
  String no_apps_in_category(Object category) {
    return '$category 分类下没有应用';
  }

  @override
  String get loading_categories => '加载分类中……';

  @override
  String get no_categories_found => '无分类';

  @override
  String get on_device => '此设备';

  @override
  String get favourites => '收藏';

  @override
  String get loading_repository => '加载存储库…';

  @override
  String get unable_to_load_repository => '无法加载存储库';

  @override
  String get repository_loading_error_descrption => '请检查您的网络连接或存储库设置，然后重试。';

  @override
  String get appUpdateAvailable => '可用更新';

  @override
  String get releaseNotes => '发行版记录';

  @override
  String get dismiss => '忽略';

  @override
  String get viewOnGithub => '在 GitHub 中查看';

  @override
  String get update => '更新';

  @override
  String get installing => '安装中……';

  @override
  String get downloadFailed => 'APK 下载失败';

  @override
  String get remove_from_favourites => '取消收藏';

  @override
  String get add_to_favourites => '添加收藏';

  @override
  String get view_details => '查看详情';

  @override
  String installation_started(Object appName) {
    return '$appName 开始安装！';
  }

  @override
  String installation_failed_with_error(Object error) {
    return '安装失败：$error';
  }

  @override
  String download_started(Object appName) {
    return '$appName 开始下载！';
  }

  @override
  String download_failed_with_error(Object error) {
    return '下载失败：$error';
  }

  @override
  String get start_setup => '开始设置';

  @override
  String get continue_text => '继续';

  @override
  String get loading_changelog => '加载更新日志中……';

  @override
  String get appearance => '外观';

  @override
  String get theme_mode => '主题';

  @override
  String get follow_system_theme => '跟随系统设置';

  @override
  String get light_theme => '浅色主题';

  @override
  String get dark_theme => '暗色主题';

  @override
  String get dynamic_color => '动态颜色';

  @override
  String get material_you_dynamic => 'Material You Dynamic';

  @override
  String get use_system_colors_supported_android => '使用系统支持的颜色';

  @override
  String get theme_style => '主题样式';

  @override
  String get material_style => 'Material 样式';

  @override
  String get dark_knight => 'Dark Knight';

  @override
  String get dark_knight_subtitle => '深色、高对比度的Florid启发主题';

  @override
  String get florid_style => 'Florid 样式';

  @override
  String get beta => 'Beta';

  @override
  String get other => '其他';

  @override
  String get show_whats_new => '查看最新内容';

  @override
  String get feedback_on_florid_theme => '反馈Florid主题';

  @override
  String get help_improve_florid_theme_feedback => '通过提供反馈帮助改善Florid的主题';

  @override
  String get system_installer => '系统安装程序';

  @override
  String get shizuku => 'Shizuku';

  @override
  String get installation_method => '安装方式';

  @override
  String get requires_shizuku_running => '需要Shizuku运行';

  @override
  String get uses_standard_system_installer => '使用标准系统安装程序';

  @override
  String get open_shizuku => '打开 Shizuku';

  @override
  String get use_system_installer => '使用系统安装程序';

  @override
  String get close => '关闭';

  @override
  String get wifi_only => '仅无线网络';

  @override
  String get wifi_and_charging => '无线网络且充电状态下';

  @override
  String get mobile_data_or_wifi => '移动数据或无线网络';

  @override
  String get every_1_hour => '每1小时';

  @override
  String get every_2_hours => '每2小时';

  @override
  String get every_3_hours => '每3小时';

  @override
  String get every_6_hours => '每6小时';

  @override
  String get every_12_hours => '每12小时';

  @override
  String get daily => '每日';

  @override
  String every_hours(int hours) {
    return '每$hours小时';
  }

  @override
  String get update_network => '更新网络';

  @override
  String get update_interval => '更新间隔';

  @override
  String get app_management => '应用管理';

  @override
  String get alpha => 'Alpha';

  @override
  String get downloads_and_storage => '下载 & 存储';

  @override
  String get auto_install_after_download => '下载后自动安装';

  @override
  String get auto_install_after_download_subtitle => '下载完成后自动安装 APK';

  @override
  String get delete_apk_after_install => '安装后删除 APK';

  @override
  String get delete_apk_after_install_subtitle => '成功安装后删除安装程序文件';

  @override
  String get background_updates => '后台更新';

  @override
  String get check_updates_in_background => '在后台检查更新';

  @override
  String get notify_when_updates_available => '更新可用时通知';

  @override
  String get reliability => '可用性';

  @override
  String get disable_battery_optimization => '禁用电池优化';

  @override
  String get allow_background_checks_reliably => '允许后台检查可用性';

  @override
  String get run_debug_check_10s => '运行10秒的调试检查';

  @override
  String get run_debug_check_10s_subtitle => '显示测试通知并在10秒后运行';

  @override
  String get debug_check_scheduled => '已排程侦错检查';

  @override
  String get debug_update_check_runs_10s => '侦错更新检查将在10秒后执行';

  @override
  String get no_recently_updated_apps => '无最近更新的应用程序';

  @override
  String get no_new_apps => '无新应用';

  @override
  String get monthly_top_apps => '月度热门应用';

  @override
  String get from_izzyondroid => '来自 IzzyOnDroid';

  @override
  String get sync_required => '需要同步';

  @override
  String get izzyondroid_sync_required_message =>
      '需要同步 IzzyOnDroid 存储库以显示热门应用程序。';

  @override
  String get go_to_settings => '前往设置';

  @override
  String get keep_android_open => '保持 Android 开放';

  @override
  String get keep_android_open_message =>
      '从 2026/2027 年开始，谷歌将要求所有在认证设备上安装的 Android 应用（包括从 Play 商店之外安装的应用）都必须经过开发者验证。';

  @override
  String get ignore => '忽略';

  @override
  String get learn_more => '了解更多';

  @override
  String get search_fdroid_apps => '搜索 F-Droid 应用……';

  @override
  String get filters => '筛选';

  @override
  String get search_apps => '搜索应用';

  @override
  String get search_failed => '搜索失败';

  @override
  String get unknown_error_occurred => '发生未知错误';

  @override
  String get try_different_keywords => '尝试不同的关键字或检查拼写';

  @override
  String get popular_searches => '热门搜索：';

  @override
  String get clear_all => '清除所有';

  @override
  String get sort_by => '排序';

  @override
  String get relevance => '关系程度';

  @override
  String get name_az => '名称(A-Z)';

  @override
  String get name_za => '名称(Z-A)';

  @override
  String get recently_added => '最近添加';

  @override
  String get no_categories_available => '无分类可用';

  @override
  String get repositories => '存储库';

  @override
  String get apply_filters => '应用筛选';

  @override
  String search_results_for_query(int count, Object query) {
    return '找到 $count 条关于 “$query” 的结果';
  }

  @override
  String get loading_top_apps => '正在加载热门应用……';

  @override
  String get failed_to_load_apps => '加载应用失败';

  @override
  String get try_again => '重试';

  @override
  String get no_apps_from_izzyondroid => '没有来自 IzzyOnDroid 的应用';

  @override
  String get no_favourites_yet => '无收藏应用';

  @override
  String get tap_star_to_save => '点击星形以将其保存在此处';

  @override
  String update_failed_with_error(Object error) {
    return '更新失败：$error';
  }

  @override
  String get user => '用户';

  @override
  String auto_install_failed_with_error(Object error) {
    return '自动安装失败：$error';
  }

  @override
  String installing_app(Object appName) {
    return '安装 $appName 中……';
  }

  @override
  String get install_from_repository => '从存储库安装';

  @override
  String get download_from_repository => '从存储库下载';

  @override
  String choose_repository_for_action(Object action) {
    return '你可以选择使用哪个仓库来$action这个应用。';
  }

  @override
  String get unknown => '未知';

  @override
  String previously_installed_from(Object repositoryName) {
    return '此前安装来源：$repositoryName';
  }

  @override
  String get previously_installed_from_here => '以前从此处安装';

  @override
  String get default_repository => '默认';

  @override
  String by_author(Object author) {
    return '来自 $author';
  }

  @override
  String check_out_on_fdroid(Object appName, Object packageName) {
    return '在 F-Droid 上查看 $appName：https://f-droid.org/packages/$packageName/';
  }

  @override
  String get rebuild_repositories => '重建存储库';

  @override
  String get preset => '预设';

  @override
  String get your_repositories => '你的存储库';

  @override
  String get no_custom_repositories => '未添加自定义存储库';

  @override
  String get add_custom_repository_to_start => '添加自定义 F-Droid 源以开始';

  @override
  String get scan => '扫描';

  @override
  String get point_camera_qr => '将镜头对准二维码';

  @override
  String get tap_keyboard_enter_url => '点击键盘输入 URL';

  @override
  String get loading_repository_configuration => '加载存储库配置中……';

  @override
  String get adding_selected_repositories => '正在导入选中的存储库……';

  @override
  String get fetching_fdroid_repository_index => '正在同步 F-Droid 仓库索引……';

  @override
  String get importing_apps_to_database => '正在将应用导入数据库……';

  @override
  String importing_apps_to_database_seconds(int seconds) {
    return '正在将应用导入数据库...（$seconds 秒）';
  }

  @override
  String get loading_custom_repositories => '正在加载自定义存储库……';

  @override
  String get setup_complete => '已配置完成！';

  @override
  String get welcome_to => '欢迎使用';

  @override
  String get onboarding_intro_subtitle =>
      '一款现代 F-Droid 客户端，让你轻松浏览、搜索和下载开源 Android 应用。';

  @override
  String get curated_open_source_apps => '精选开源应用';

  @override
  String get safe_downloads => '保存下载';

  @override
  String get updates_and_notifications => '更新 & 通知';

  @override
  String get add_extra_repositories => '添加额外存储库';

  @override
  String get repos_step_description =>
      'Florid 预装了官方 F-Droid 软件源。您还可以添加可信的社区软件源来获取更多应用。';

  @override
  String get available_repositories => '可用存储库';

  @override
  String get manage_repositories_anytime => '您可以在“设置”中随时添加或删除存储库。';

  @override
  String get request_permissions => '请求权限';

  @override
  String get permissions_step_description => 'Florid 需要一些权限才能为您提供最佳体验。';

  @override
  String get notifications => '通知';

  @override
  String get get_notified_updates => '应用更新时收到通知';

  @override
  String get app_installation => '应用安装';

  @override
  String get allow_florid_install_apps => '允许 Florid 安装下载的应用';

  @override
  String get enable_permissions_anytime => '您可以随时在设置中启用这些权限。';

  @override
  String get setting_up_florid => '配置 Florid';

  @override
  String get no_antifeature_listed => '未列出反特性';

  @override
  String get open_link => '打开链接';

  @override
  String get loading_recently_updated_apps => '加载最近更新的应用程序……';

  @override
  String get checking_for_updates => '检查更新中';

  @override
  String get import_favourites => '导入收藏夹';

  @override
  String get merge => '合并';

  @override
  String get update_all => '更新所有';

  @override
  String get apps => '应用';

  @override
  String get troubleshooting => '故障排除';

  @override
  String get replace => '替换';

  @override
  String get your_name => '你的昵称';

  @override
  String get enter_your_name => '输入你的昵称';
}
