// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get app_name => 'Florid';

  @override
  String get welcome => 'Florid へようこそ';

  @override
  String get search => '検索';

  @override
  String get settings => '設定';

  @override
  String get home => 'ホーム';

  @override
  String get categories => 'カテゴリ';

  @override
  String get updates => '更新';

  @override
  String get installed => 'インストール済み';

  @override
  String get download => 'ダウンロード';

  @override
  String get install => 'インストール';

  @override
  String get uninstall => 'アンインストール';

  @override
  String get open => '開く';

  @override
  String get cancel => 'キャンセル';

  @override
  String get update_available => '更新あり';

  @override
  String get downloading => 'ダウンロード中...';

  @override
  String get install_permission_required => 'インストール権限が必要です';

  @override
  String get storage_permission_required => 'ストレージ権限が必要です';

  @override
  String get cancel_download => 'ダウンロードをキャンセル';

  @override
  String get version => 'バージョン';

  @override
  String get size => 'サイズ';

  @override
  String get description => '説明';

  @override
  String get permissions => '権限';

  @override
  String get screenshots => 'スクリーンショット';

  @override
  String get no_version_available => '利用可能なバージョンがありません';

  @override
  String get app_information => 'アプリ情報';

  @override
  String get package_name => 'パッケージ名';

  @override
  String get license => 'ライセンス';

  @override
  String get added => '追加日';

  @override
  String get last_updated => '最終更新';

  @override
  String get version_information => 'バージョン情報';

  @override
  String get version_name => 'バージョン名';

  @override
  String get version_code => 'バージョンコード';

  @override
  String get min_sdk => '最小 SDK';

  @override
  String get target_sdk => 'ターゲット SDK';

  @override
  String get all_versions => 'すべてのバージョン';

  @override
  String get latest => '最新';

  @override
  String get released => 'リリース日';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get share => '共有';

  @override
  String get website => 'ウェブサイト';

  @override
  String get source_code => 'ソースコード';

  @override
  String get issue_tracker => '課題トラッカー';

  @override
  String get whats_new => '新機能';

  @override
  String get show_more => 'もっと見る';

  @override
  String get show_less => '閉じる';

  @override
  String get downloads_stats => 'ダウンロード統計';

  @override
  String get last_day => '過去 1 日';

  @override
  String get last_30_days => '過去 30 日';

  @override
  String get last_365_days => '過去 365 日';

  @override
  String get not_available => '利用不可';

  @override
  String get download_failed => 'ダウンロードに失敗しました';

  @override
  String get installation_failed => 'インストールに失敗しました';

  @override
  String get uninstall_failed => 'アンインストールに失敗しました';

  @override
  String get open_failed => '開けませんでした';

  @override
  String get device => 'デバイス';

  @override
  String get recently_updated => '最近の更新';

  @override
  String get refresh => '更新';

  @override
  String get about => 'このアプリについて';

  @override
  String get refreshing_data => 'データを更新中...';

  @override
  String get data_refreshed => 'データを更新しました';

  @override
  String get refresh_failed => '更新に失敗しました';

  @override
  String get loading_latest_apps => '最新アプリを読み込み中...';

  @override
  String get latest_apps => '最新アプリ';

  @override
  String get no_apps_found => 'アプリが見つかりません';

  @override
  String get searching => '検索中...';

  @override
  String get setup_failed => 'セットアップに失敗しました';

  @override
  String get back => '戻る';

  @override
  String get allow => '許可';

  @override
  String get manage_repositories => 'リポジトリを管理';

  @override
  String get enable_disable => '有効/無効';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get delete_repository => 'リポジトリを削除';

  @override
  String delete_repository_confirm(Object name, Object repository) {
    return '「$name」を削除してもよろしいですか？';
  }

  @override
  String get updating_repository => 'リポジトリを更新中';

  @override
  String get touch_grass_message => '外の空気を吸うのにぴったりの時間です！';

  @override
  String get add_repository => 'リポジトリを追加';

  @override
  String get add => '追加';

  @override
  String get save => '保存';

  @override
  String get enter_repository_name => 'リポジトリ名を入力してください';

  @override
  String get enter_repository_url => 'リポジトリ URL を入力してください';

  @override
  String get edit_repository => 'リポジトリを編集';

  @override
  String get loading_apps => 'アプリを読み込み中...';

  @override
  String no_apps_in_category(Object category) {
    return '$category にアプリが見つかりません';
  }

  @override
  String get loading_categories => 'カテゴリを読み込み中...';

  @override
  String get no_categories_found => 'カテゴリが見つかりません';

  @override
  String get on_device => 'デバイス上';

  @override
  String get favourites => 'お気に入り';

  @override
  String get loading_repository => 'リポジトリを読み込み中…';

  @override
  String get unable_to_load_repository => 'リポジトリを読み込めません';

  @override
  String get repository_loading_error_descrption =>
      '接続またはリポジトリ設定を確認して、もう一度お試しください。';

  @override
  String get appUpdateAvailable => '更新あり';

  @override
  String get releaseNotes => 'リリースノート';

  @override
  String get dismiss => '閉じる';

  @override
  String get viewOnGithub => 'GitHub で表示';

  @override
  String get update => '更新';

  @override
  String get installing => 'インストール中...';

  @override
  String get downloadFailed => 'APK のダウンロードに失敗しました';

  @override
  String get remove_from_favourites => 'お気に入りから削除';

  @override
  String get add_to_favourites => 'お気に入りに追加';

  @override
  String get view_details => '詳細を表示';

  @override
  String installation_started(Object appName) {
    return '$appName のインストールを開始しました！';
  }

  @override
  String installation_failed_with_error(Object error) {
    return 'インストールに失敗しました: $error';
  }

  @override
  String download_started(Object appName) {
    return '$appName のダウンロードを開始しました！';
  }

  @override
  String download_failed_with_error(Object error) {
    return 'ダウンロードに失敗しました: $error';
  }

  @override
  String get start_setup => 'セットアップを開始';

  @override
  String get continue_text => '続ける';

  @override
  String get loading_changelog => '変更履歴を読み込み中...';

  @override
  String get appearance => '外観';

  @override
  String get theme_mode => 'テーマモード';

  @override
  String get follow_system_theme => 'システム設定に従う';

  @override
  String get light_theme => 'ライトテーマ';

  @override
  String get dark_theme => 'ダークテーマ';

  @override
  String get dynamic_color => 'ダイナミックカラー';

  @override
  String get material_you_dynamic => 'Material You Dynamic';

  @override
  String get use_system_colors_supported_android =>
      '対応する Android デバイスでシステムカラーを使用';

  @override
  String get theme_style => 'テーマスタイル';

  @override
  String get material_style => 'Material スタイル';

  @override
  String get dark_knight => 'Dark Knight';

  @override
  String get dark_knight_subtitle => 'ダークで高コントラストな Florid 風テーマ';

  @override
  String get florid_style => 'Florid スタイル';

  @override
  String get beta => 'ベータ';

  @override
  String get other => 'その他';

  @override
  String get show_whats_new => '新機能を表示';

  @override
  String get show_monthly_top_apps => '月間トップアプリを表示';

  @override
  String get feedback_on_florid_theme => 'Florid テーマへのフィードバック';

  @override
  String get help_improve_florid_theme_feedback =>
      'フィードバックで Florid テーマの改善にご協力ください';

  @override
  String get system_installer => 'システムインストーラー';

  @override
  String get shizuku => 'Shizuku';

  @override
  String get installation_method => 'インストール方法';

  @override
  String get requires_shizuku_running => 'Shizuku の起動が必要です';

  @override
  String get uses_standard_system_installer => '標準のシステムインストーラーを使用します';

  @override
  String get open_shizuku => 'Shizuku を開く';

  @override
  String get use_system_installer => 'システムインストーラーを使用';

  @override
  String get close => '閉じる';

  @override
  String get wifi_only => 'Wi-Fi のみ';

  @override
  String get wifi_and_charging => 'Wi-Fi + 充電中';

  @override
  String get mobile_data_or_wifi => 'モバイルデータまたは Wi-Fi';

  @override
  String get every_1_hour => '1 時間ごと';

  @override
  String get every_2_hours => '2 時間ごと';

  @override
  String get every_3_hours => '3 時間ごと';

  @override
  String get every_6_hours => '6 時間ごと';

  @override
  String get every_12_hours => '12 時間ごと';

  @override
  String get daily => '毎日';

  @override
  String every_hours(int hours) {
    return '$hours 時間ごと';
  }

  @override
  String get update_network => '更新時のネットワーク';

  @override
  String get update_interval => '更新間隔';

  @override
  String get app_management => 'アプリ管理';

  @override
  String get alpha => 'アルファ';

  @override
  String get privacy => 'プライバシー';

  @override
  String get opt_out_of_telemetry => 'テレメトリをオプトアウト';

  @override
  String get opt_out_of_telemetry_subtitle => 'アクティブユーザー数（匿名）の把握に役立ちます';

  @override
  String get downloads_and_storage => 'ダウンロードとストレージ';

  @override
  String get auto_install_after_download => 'ダウンロード後に自動インストール';

  @override
  String get auto_install_after_download_subtitle =>
      'ダウンロード完了後に APK を自動的にインストール';

  @override
  String get delete_apk_after_install => 'インストール後に APK を削除';

  @override
  String get delete_apk_after_install_subtitle => 'インストール成功後にインストーラーファイルを削除';

  @override
  String get background_updates => 'バックグラウンド更新';

  @override
  String get check_updates_in_background => 'バックグラウンドで更新を確認';

  @override
  String get notify_when_updates_available => '更新があるときに通知';

  @override
  String get reliability => '信頼性';

  @override
  String get disable_battery_optimization => 'バッテリー最適化を無効化';

  @override
  String get allow_background_checks_reliably => 'バックグラウンドチェックを確実に実行';

  @override
  String get run_debug_check_10s => '10 秒後にデバッグチェックを実行';

  @override
  String get run_debug_check_10s_subtitle => 'テスト通知を表示し、10 秒後に実行します';

  @override
  String get debug_check_scheduled => 'デバッグチェックをスケジュールしました';

  @override
  String get debug_update_check_runs_10s => 'デバッグ更新チェックは 10 秒後に実行されます';

  @override
  String get no_recently_updated_apps => '最近更新されたアプリはありません';

  @override
  String get no_new_apps => '新しいアプリはありません';

  @override
  String get monthly_top_apps => '月間トップアプリ';

  @override
  String get from_izzyondroid => 'IzzyOnDroid より';

  @override
  String get sync_required => '同期が必要です';

  @override
  String get izzyondroid_sync_required_message =>
      'トップアプリを表示するには IzzyOnDroid リポジトリの同期が必要です。';

  @override
  String get go_to_settings => '設定へ';

  @override
  String get keep_android_open => 'Android をオープンに';

  @override
  String get keep_android_open_message =>
      '2026/2027 年以降、Google は Play ストア以外からインストールしたアプリを含め、認証済みデバイス上のすべての Android アプリに開発者認証を義務付けます。';

  @override
  String get ignore => '無視';

  @override
  String get learn_more => '詳細を見る';

  @override
  String get search_fdroid_apps => 'F-Droid アプリを検索...';

  @override
  String get filters => 'フィルター';

  @override
  String get search_apps => 'アプリを検索';

  @override
  String get search_failed => '検索に失敗しました';

  @override
  String get unknown_error_occurred => '不明なエラーが発生しました';

  @override
  String get try_different_keywords => '別のキーワードを試すか、スペルを確認してください';

  @override
  String get popular_searches => '人気の検索:';

  @override
  String get clear_all => 'すべてクリア';

  @override
  String get sort_by => '並べ替え';

  @override
  String get relevance => '関連度';

  @override
  String get name_az => '名前 (A-Z)';

  @override
  String get name_za => '名前 (Z-A)';

  @override
  String get recently_added => '最近追加';

  @override
  String get no_categories_available => '利用可能なカテゴリがありません';

  @override
  String get repositories => 'リポジトリ';

  @override
  String get apply_filters => 'フィルターを適用';

  @override
  String search_results_for_query(int count, Object query) {
    return '「$query」の検索結果 $count 件';
  }

  @override
  String get loading_top_apps => 'トップアプリを読み込み中...';

  @override
  String get failed_to_load_apps => 'アプリの読み込みに失敗しました';

  @override
  String get try_again => '再試行';

  @override
  String get no_apps_from_izzyondroid => 'IzzyOnDroid からのアプリはありません';

  @override
  String get no_favourites_yet => 'お気に入りはまだありません';

  @override
  String get tap_star_to_save => 'アプリの星をタップしてここに保存';

  @override
  String update_failed_with_error(Object error) {
    return '更新に失敗しました: $error';
  }

  @override
  String get user => 'ユーザー';

  @override
  String auto_install_failed_with_error(Object error) {
    return '自動インストールに失敗しました: $error';
  }

  @override
  String installing_app(Object appName) {
    return '$appName をインストール中...';
  }

  @override
  String get install_from_repository => 'リポジトリからインストール';

  @override
  String get download_from_repository => 'リポジトリからダウンロード';

  @override
  String choose_repository_for_action(Object action) {
    return 'このアプリを$actionするリポジトリを選択できます。';
  }

  @override
  String get unknown => '不明';

  @override
  String previously_installed_from(Object repositoryName) {
    return '以前のインストール元: $repositoryName';
  }

  @override
  String get previously_installed_from_here => '以前ここからインストール済み';

  @override
  String get default_repository => 'デフォルト';

  @override
  String by_author(Object author) {
    return '作者: $author';
  }

  @override
  String check_out_on_fdroid(Object appName, Object packageName) {
    return 'F-Droid で $appName をチェック: https://f-droid.org/packages/$packageName/';
  }

  @override
  String get rebuild_repositories => 'リポジトリを再構築';

  @override
  String get preset => 'プリセット';

  @override
  String get your_repositories => 'あなたのリポジトリ';

  @override
  String get no_custom_repositories => 'カスタムリポジトリは追加されていません';

  @override
  String get add_custom_repository_to_start => 'カスタム F-Droid リポジトリを追加して始めましょう';

  @override
  String get scan => 'スキャン';

  @override
  String get point_camera_qr => 'カメラを QR コードに向けてください';

  @override
  String get tap_keyboard_enter_url => 'キーボードをタップして URL を手動入力';

  @override
  String get loading_repository_configuration => 'リポジトリ設定を読み込み中...';

  @override
  String get adding_selected_repositories => '選択したリポジトリを追加中...';

  @override
  String get fetching_fdroid_repository_index => 'F-Droid リポジトリインデックスを取得中...';

  @override
  String get importing_apps_to_database => 'アプリをデータベースにインポート中...';

  @override
  String importing_apps_to_database_seconds(int seconds) {
    return 'アプリをデータベースにインポート中... ($seconds秒)';
  }

  @override
  String get loading_custom_repositories => 'カスタムリポジトリを読み込み中...';

  @override
  String get setup_complete => 'セットアップ完了！';

  @override
  String get welcome_to => 'ようこそ';

  @override
  String get onboarding_intro_subtitle =>
      'オープンソース Android アプリを簡単に閲覧・検索・ダウンロードできるモダンな F-Droid クライアントです。';

  @override
  String get curated_open_source_apps => '厳選されたオープンソースアプリ';

  @override
  String get safe_downloads => '安全なダウンロード';

  @override
  String get updates_and_notifications => '更新と通知';

  @override
  String get add_extra_repositories => '追加リポジトリを登録';

  @override
  String get repos_step_description =>
      'Florid には公式 F-Droid リポジトリが同梱されています。信頼できるコミュニティリポジトリを追加して、より多くのアプリを入手できます。';

  @override
  String get available_repositories => '利用可能なリポジトリ';

  @override
  String get manage_repositories_anytime => '設定からいつでもリポジトリを追加・削除できます。';

  @override
  String get request_permissions => '権限のリクエスト';

  @override
  String get permissions_step_description =>
      'Florid は最高の体験を提供するためにいくつかの権限が必要です。';

  @override
  String get notifications => '通知';

  @override
  String get get_notified_updates => 'アプリが更新されたときに通知を受け取る';

  @override
  String get app_installation => 'アプリのインストール';

  @override
  String get allow_florid_install_apps => 'Florid がダウンロードしたアプリをインストールできるようにする';

  @override
  String get enable_permissions_anytime => 'これらの権限は設定からいつでも有効にできます。';

  @override
  String get setting_up_florid => 'Florid をセットアップ中';

  @override
  String get no_antifeature_listed => 'アンチ機能は記載されていません';

  @override
  String get open_link => 'リンクを開く';

  @override
  String get loading_recently_updated_apps => '最近更新されたアプリを読み込み中...';

  @override
  String get checking_for_updates => '更新を確認中';

  @override
  String get import_favourites => 'お気に入りをインポート';

  @override
  String get merge => 'マージ';

  @override
  String get update_all => 'すべて更新';

  @override
  String get apps => 'アプリ';

  @override
  String get troubleshooting => 'トラブルシューティング';

  @override
  String get replace => '置き換え';

  @override
  String get your_name => 'お名前';

  @override
  String get enter_your_name => 'お名前を入力';

  @override
  String get top_apps => 'トップアプリ';

  @override
  String get games => 'ゲーム';

  @override
  String get auth_all_apps => 'すべてのアプリ';

  @override
  String get auth_all_apps_desc => 'すべてのインストールに認証を要求';

  @override
  String get auth_all_apps_w_anti_feat => 'アンチ機能のあるアプリ';

  @override
  String get auth_all_apps_w_anti_feat_desc => 'アンチ機能のあるアプリのインストール時のみ認証を要求します。';

  @override
  String get support_the_developer => '開発者を支援';

  @override
  String available_on_repository(Object repositoryName) {
    return '利用可能: $repositoryName';
  }

  @override
  String also_available_from_repositories(Object repositoryNames) {
    return '他のリポジトリでも利用可能: $repositoryNames';
  }

  @override
  String get onboarding_setup_type => 'セットアップタイプ';

  @override
  String get onboarding_setup_type_desc => 'Florid のセットアップ方法を選択';

  @override
  String get onboarding_setup_basic => '基本セットアップ';

  @override
  String get onboarding_setup_basic_desc => '推奨リポジトリでクイックスタート';

  @override
  String get onboarding_setup_advanced => '詳細セットアップ';

  @override
  String get onboarding_setup_advanced_desc => 'リポジトリと設定をカスタマイズ';

  @override
  String get help_us_improve_florid => 'Florid の改善にご協力ください';

  @override
  String section_app_count(Object appCount) {
    return '$appCount 件のアプリ';
  }

  @override
  String get ignore_future_updates => '今後の更新を無視';

  @override
  String get general_settings => '一般設定';

  @override
  String get view_favourite_apps_subtitle => 'お気に入りアプリを表示';

  @override
  String get appearance_subtitle => 'テーマモードとスタイル';

  @override
  String get parental_control => 'ペアレンタルコントロール';

  @override
  String get parental_control_subtitle => 'アンチ機能アプリの非表示とインストール保護';

  @override
  String get app_content_language => 'アプリ表示言語';

  @override
  String get repositories_and_management => 'リポジトリと管理';

  @override
  String get manage_repositories_subtitle => 'F-Droid リポジトリの追加・削除';

  @override
  String get app_management_subtitle => 'インストールと更新に関する設定';

  @override
  String get miscellaneous => 'その他';

  @override
  String get troubleshooting_subtitle => 'ストレージ、キャッシュ、ダウンロード';

  @override
  String get florid_tagline => 'モダンな F-Droid クライアント。';

  @override
  String get source_code_subtitle => 'GitHub で Florid のソースコードを表示';

  @override
  String get telegram => 'Telegram';

  @override
  String get telegram_subtitle => 'Telegram コミュニティに参加';

  @override
  String get matrix => 'Matrix';

  @override
  String get matrix_subtitle => 'Matrix コミュニティに参加';

  @override
  String get report_an_issue => '問題を報告';

  @override
  String get report_an_issue_subtitle => 'バグを見つけましたか？お知らせください！';

  @override
  String get donate => '寄付';

  @override
  String get donate_subtitle => 'Florid の開発を支援';

  @override
  String get share_florid => 'Florid を共有';

  @override
  String get share_florid_subtitle => '詳しい友達に Florid を教えましょう！';

  @override
  String get share_florid_title => 'Florid をチェック！';

  @override
  String get share_florid_message =>
      'モダンな F-Droid クライアント！ https://github.com/Nandanrmenon/florid';

  @override
  String get select_language => '言語を選択';

  @override
  String language_changed_to(Object language) {
    return '言語を $language に変更しました。';
  }

  @override
  String get export_favourites => 'お気に入りをエクスポート';

  @override
  String get no_favourites_to_export => 'エクスポートするお気に入りがありません';

  @override
  String get unable_to_access_downloads => 'ダウンロードフォルダにアクセスできません';

  @override
  String saved_to_downloads(Object path) {
    return 'ダウンロードに保存しました: $path';
  }

  @override
  String get no_favourites_to_import => 'インポートするお気に入りが見つかりません';

  @override
  String favourites_import_found(int count, Object fileName) {
    return '$fileName に $count 件のお気に入りが見つかりました。';
  }

  @override
  String favourites_imported(int count) {
    return '$count 件のお気に入りをインポートしました';
  }
}
