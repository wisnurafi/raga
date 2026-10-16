import 'package:flutter/material.dart';

import '../state/app_state.dart';

// String table for the two supported locales. Every UI string lives
// here — no hardcoded Indonesian/English anywhere in the widgets.
// Templates use {name} placeholders, filled by [tx]/[txl].
// Lookup falls back to Indonesian, then to the key itself (a missing
// key shows up loudly in QA instead of silently blank).
const Map<String, Map<String, String>> _strings = {
  'id': {
    // --- shared actions ---
    'cancel': 'Batal',
    'close': 'Tutup',
    'save': 'Simpan',
    'delete': 'Hapus',
    'continue': 'Lanjut',
    'male': 'Pria',
    'female': 'Wanita',
    'add': 'Tambah',

    // --- splash ---
    'splash_tagline': 'Kenali tubuhmu, jaga kesehatanmu.',
    'splash_loading': 'Memuat...',

    // --- home ---
    'home_title': 'Hitung BMI',
    'home_tip_today': 'Tips hari ini',
    'home_body_data': 'Data tubuh',
    'home_height': 'Tinggi badan',
    'home_weight': 'Berat badan',
    'home_calc': 'Hitung BMI',
    'age_years': '{n} thn',

    // --- history ---
    'history_title': 'Riwayat',
    'history_empty': 'Belum ada catatan.',
    'range_7d': '7 hari',
    'range_30d': '30 hari',
    'range_3m': '3 bulan',
    'range_6m': '6 bulan',
    'range_all': 'Semua',
    'history_weight_kg': 'Berat badan (kg)',
    'history_weight_lb': 'Berat badan (lb)',
    'history_weight': 'Berat',
    'history_stable': 'stabil · {span}',
    'history_stats':
        'Rata-rata {a}{u} · Terendah {l}{u} · Tertinggi {h}{u}',
    'history_insight': 'Insight',
    'history_recent': 'Catatan terakhir',
    'history_show_less': 'Tampilkan lebih sedikit',
    'history_show_all': 'Tampilkan semua ({n})',
    'chart_empty': 'Belum ada data grafik.',

    // --- result ---
    'result_title': 'Hasil BMI',
    'result_tips': 'Tips untukmu',
    'result_saving': 'Menyimpan…',
    'result_save': 'Simpan ke riwayat',
    'result_sharing': 'Membagikan…',
    'result_share': 'Bagikan',
    'result_healthy_range': 'Rentang berat sehat',
    'result_for_height': 'Untuk tinggi {h}: {lo} – {hi}',
    'result_below': 'Kamu {w} — {d} di bawah rentang sehat.',
    'result_above': 'Kamu {w} — {d} di atas rentang sehat.',
    'result_inside': 'Kamu {w} — di dalam rentang sehat ✓',
    'result_already_target': 'Sudah jadi target',
    'result_set_target': 'Jadikan target',
    'result_target_saved': 'Target {t} tersimpan — cek tab Streak.',
    'result_saved': 'Tersimpan di riwayat.',
    'result_share_fail': 'Gagal membuat gambar.',
    'result_share_text': 'BMI saya {bmi} ({cat}) — dihitung dengan Raga',

    // --- health ---
    'health_title': 'Kesehatan',
    'activity_minimal': 'Minim',
    'activity_light': 'Ringan',
    'activity_moderate': 'Sedang',
    'activity_active': 'Berat',
    'health_calorie_need': 'Kebutuhan kalori harian',
    'health_bmr_line': 'BMR {bmr} kcal/hari · rumus Mifflin-St Jeor',
    'goal_lose': 'Turun',
    'goal_maintain': 'Jaga',
    'goal_gain': 'Naik',
    'health_ideal': 'Berat badan ideal',
    'health_you': 'Kamu: {v} {u}',
    'profile_line': '{gender} · {n} th · {h}',

    // --- streak ---
    'streak_title': 'Streak',
    'streak_done': 'Minggu ini sudah timbang ✓',
    'streak_todo': 'Timbang minggu ini biar streak lanjut',
    'streak_goals': 'Goals',
    'streak_goal_weight': 'Target berat',
    'streak_no_goal': 'Belum ada target — ketuk untuk atur',
    'streak_goal_maintain': 'Jaga di {g}',
    'streak_goal_down': 'Turun ke {g}',
    'streak_goal_up': 'Naik ke {g}',
    'streak_last8': '8 minggu terakhir',
    'streak_all_done': 'Semua milestone tercapai!',
    'streak_next': 'Target berikutnya: {w}',
    'streak_togo': '{w} lagi',
    'streak_keep': 'Konsisten banget — pertahankan!',
    'streak_dialog_stay': 'Tetap di {w}',
    'streak_dialog_togo': '{s}{w} lagi',
    'streak_save_goal': 'Simpan target',
    'streak_delete_goal': 'Hapus target',

    // --- onboarding ---
    'ob1_title': 'Kenalan dulu, yuk',
    'ob1_sub': 'Biar Raga bisa menyapamu dan menghitung dengan tepat.',
    'ob1_name': 'Nama panggilan',
    'ob1_age': 'Umur',
    'ob1_gender': 'Jenis kelamin',
    'ob2_title': 'Ukuran tubuhmu',
    'ob2_sub': 'Dipakai untuk menghitung BMI awalmu.',
    'ob2_bmi': 'BMI awalmu',
    'ob_optional': 'OPSIONAL',
    'ob3_title': 'Punya target berat?',
    'ob3_sub': 'Atur sekarang atau nanti di Profil. Boleh dilewati.',
    'ob3_hint_stay': 'Tetap di {w}',
    'ob3_hint_diff': 'Sekarang {w} · selisih {s}{d} {u}',
    'ob3_pace': 'Laju per minggu',
    'ob3_eta': 'Perkiraan tercapai',
    'ob3_eta_weeks': '±{w} · {date}',
    'ob4_title': 'Jadwal menimbang',
    'ob4_sub':
        'Pilih hari dan jam, Raga akan mengingatkanmu. Boleh dilewati.',
    'ob4_time': 'Jam pengingat',
    'ob4_summary': 'Ringkasan',
    'ob4_note': 'Bisa diubah kapan saja di Profil.',
    'ob_done': 'Selesai',
    'ob_skip': 'Lewati dulu',
    'ob_need_name': 'Isi nama panggilan dulu',
    'ob_notif_off': 'Nyalakan notifikasi di pengaturan sistem dulu',
    'ob_exact_off': 'Aktifkan "Alarm & pengingat" di pengaturan sistem, '
        'lalu atur pengingatnya dari Profil.',

    // --- profile sheet ---
    'sheet_edit': 'Edit profil',
    'sheet_new': 'Profil baru',
    'sheet_name_hint': 'Nama',
    'sheet_gender': 'Jenis kelamin',
    'sheet_age': 'Umur',
    'sheet_years': 'tahun',
    'sheet_height': 'Tinggi badan',

    // --- profile screen ---
    'profile_title': 'Profil',
    'profile_longpress_hint': 'Tahan chip profil untuk menghapusnya',
    'profile_settings': 'Pengaturan',
    'profile_units': 'Unit',
    'profile_theme': 'Tema',
    'theme_dark': 'Gelap',
    'theme_light': 'Terang',
    'profile_reminder': 'Pengingat',
    'profile_reminder_on': 'Pengingat timbang mingguan aktif',
    'profile_reminder_off': 'Pengingat timbang mingguan mati',
    'profile_backup': 'Backup',
    'profile_others': 'Lainnya',
    'profile_status': 'Status',
    'profile_pending': '{n} catatan menunggu diunggah.',
    'profile_backup_code': 'Kode backup',
    'profile_code_not_ready': '(belum siap)',
    'profile_copy_code': 'Salin kode',
    'profile_code_copied': 'Kode backup disalin',
    'profile_sync_now': 'Sinkron sekarang',
    'profile_restore': 'Restore dari kode',
    'profile_backup_note':
        'Tersimpan aman di cloud pribadimu. Tanpa akun — tinggal pakai.',
    'profile_devmode': 'Mode pengembang',
    'profile_dev_on': 'Log, notifikasi tes, info server',
    'profile_dev_off': 'Perkakas tambahan untuk debugging',
    'profile_test_notif': 'Kirim notifikasi tes',
    'profile_test_notif_sub': 'Kirim satu sekarang',
    'profile_alarms': 'Alarm terdaftar',
    'profile_alarms_sub': 'Yang benar-benar didaftarkan OS',
    'profile_log': 'Log',
    'profile_log_sub': 'Diagnosa & debugging',
    'profile_wipe': 'Hapus semua data',
    'profile_version': 'Versi aplikasi',
    'profile_delete_title': 'Hapus profil?',
    'profile_delete_body':
        '{name} beserta riwayatnya akan hilang selamanya.',
    'profile_delete_last': 'Tidak bisa menghapus profil terakhir',
    'profile_replace_title': 'Ganti semuanya?',
    'profile_replace_body': 'Semua profil dan riwayat di HP ini akan '
        'diganti dengan data backup. Tidak bisa dibatalkan.',
    'profile_replace_ok': 'Restore',
    'profile_restored': 'Backup dipulihkan — selamat datang kembali.',
    'profile_restore_fail': 'Kode tidak ditemukan atau cloud tidak '
        'terjangkau. Cek kodenya lalu coba lagi.',
    'profile_test_sent': 'Notifikasi tes terkirim',
    'profile_test_fail':
        'Tidak bisa menampilkan notifikasi — cek izinnya',
    'profile_sched_title': 'Jadwal pengingat',
    'profile_next': 'Berikutnya: {t}',
    'profile_pick_day': 'Pilih minimal satu hari',
    'profile_today': 'Hari ini',
    'profile_tomorrow': 'Besok',
    'profile_arm_notif': 'Nyalakan notifikasi di pengaturan sistem dulu',
    'profile_arm_exact': 'Aktifkan "Alarm & pengingat" di pengaturan '
        'sistem, lalu nyalakan pengingatnya lagi.',
    'profile_arm_ok': 'Pengingat mingguan aktif',
    'profile_arm_late': 'Pengingat aktif, tapi alarm tepat waktu mati — '
        'bisa terlambat. Izinkan "Alarm & pengingat" di pengaturan '
        'sistem biar tepat waktu.',
    'profile_wipe_body':
        'Riwayat dan profil di perangkat ini akan hilang selamanya.',
    'profile_wiped': 'Semua data dihapus',
    'profile_alarms_empty': 'Tidak ada alarm yang terdaftar di OS.',
    'alarms_no_title': '(tanpa judul)',

    // --- restore choice (merge vs replace) ---
    'profile_restore_mode_title': 'Restore dari kode',
    'profile_restore_mode_body': 'Kode ini cocok. Gabungkan dengan data '
        'yang sudah ada di HP ini, atau ganti semuanya?',
    'profile_merge': 'Gabung',
    'profile_merged': '{n} catatan baru digabung dari backup',
    'profile_merge_empty':
        'Tidak ada catatan baru dari backup — datamu sudah lengkap.',

    // --- account: optional Google login (auth_service.dart) ---
    'auth_title': 'Akun',
    'auth_anon_note': 'Kamu memakai Raga tanpa login — semua fitur tetap '
        'jalan. Masuk dengan Google kalau mau datamu ngikut akun di HP lain.',
    'auth_sign_in_google': 'Masuk dengan Google',
    'auth_sign_in_cancelled': 'Login dibatalkan',
    'auth_not_configured': 'Login Google belum disiapkan di build ini',
    'auth_sign_in_failed': 'Gagal masuk: {e}',
    'auth_migrated': '{n} catatan dipindah ke akunmu',
    'auth_welcome': 'Selamat datang, {name}!',
    'auth_welcome_back': 'Selamat datang kembali!',
    'auth_default_name': 'Pengguna Google',
    'auth_edit_name': 'Ubah nama',
    'auth_name_title': 'Nama tampilan',
    'auth_name_hint': 'Nama tampilan',
    'auth_name_updated': 'Nama diperbarui',
    'auth_name_failed': 'Gagal menyimpan nama',
    'auth_change_photo': 'Ganti foto',
    'auth_uploading_photo': 'Mengunggah foto…',
    'auth_photo_updated': 'Foto profil diperbarui',
    'auth_photo_failed': 'Gagal mengunggah foto',
    'auth_sign_out': 'Keluar',
    'auth_sign_out_title': 'Keluar dari akun?',
    'auth_sign_out_body': 'Sesi login berakhir. Data di HP ini tetap ada '
        '— masuk lagi kapan pun untuk menyinkronkannya.',
    'auth_signed_out': 'Kamu sudah keluar',
    'auth_sync_offer_title': 'Sinkronkan data akun?',
    'auth_sync_offer_body':
        'Akun ini punya {n} catatan di cloud. Gabungkan ke HP ini?',
    'auth_sync_merge': 'Gabung',
    'auth_sync_later': 'Nanti',
    'auth_merged': '{n} catatan dari cloud digabung',
    'auth_merge_empty': 'Datamu sudah sinkron — tidak ada yang baru.',
    'auth_merge_failed': 'Gagal mengambil data cloud',

    // --- log viewer ---
    'log_hint': 'tahan baris untuk salin',
    'log_copy_all': 'Salin semua',
    'log_copied_line': 'Baris disalin',
    'log_copied_all': 'Semua log disalin',

    // --- reminder summary (bmi.dart) ---
    'rem_off': 'Mati',
    'rem_every_day': 'Setiap hari · {t}',
    'rem_per_week': '{n}× seminggu · {days} · {t}',

    // --- span labels (bmi.dart) ---
    'span_today': 'hari ini',
    'span_days': '{n} hari',
    'span_weeks': '{n} minggu',
    'span_months': '{n} bulan',

    // --- weight insight (bmi.dart) ---
    'insight_empty': 'Belum cukup data di rentang ini — timbang minimal '
        '2× biar trennya kebaca.',
    'insight_stable': 'Stabil di {w} selama {span} — pertahankan.',
    'insight_down': 'Turun {w} dalam {span}.',
    'insight_up': 'Naik {w} dalam {span}.',
    'insight_rate_ok': ' Laju ±{r}/minggu — masih dalam batas sehat.',
    'insight_rate_fast': ' Laju ±{r}/minggu — di atas anjuran umum '
        '({lim}/minggu), pertimbangkan konsultasi ahli gizi.',
    'insight_rate': ' Laju ±{r}/minggu.',
    'insight_goal_done': ' Target {w} tercapai — pertahankan!',
    'insight_goal_left': ' Kurang {w} lagi ke target.',
    'insight_goal_over': ' {w} di bawah target.',

    // --- sync status (cloud_sync.dart) ---
    'sync_not_configured': 'Belum disiapkan',
    'sync_no_connect': 'Tidak bisa terhubung',
    'sync_ok': 'Terhubung — semua sudah tersinkron',
    'sync_pending': '{n} catatan menunggu diunggah',
  },
  'en': {
    // --- shared actions ---
    'cancel': 'Cancel',
    'close': 'Close',
    'save': 'Save',
    'delete': 'Delete',
    'continue': 'Continue',
    'male': 'Male',
    'female': 'Female',
    'add': 'Add',

    // --- splash ---
    'splash_tagline': 'Know your body, take care of your health.',
    'splash_loading': 'Loading...',

    // --- home ---
    'home_title': 'BMI Calculator',
    'home_tip_today': "Today's tip",
    'home_body_data': 'Body data',
    'home_height': 'Height',
    'home_weight': 'Weight',
    'home_calc': 'Calculate BMI',
    'age_years': '{n} yrs',

    // --- history ---
    'history_title': 'History',
    'history_empty': 'No entries yet.',
    'range_7d': '7 days',
    'range_30d': '30 days',
    'range_3m': '3 months',
    'range_6m': '6 months',
    'range_all': 'All',
    'history_weight_kg': 'Weight (kg)',
    'history_weight_lb': 'Weight (lb)',
    'history_weight': 'Weight',
    'history_stable': 'steady · {span}',
    'history_stats': 'Avg {a}{u} · Low {l}{u} · High {h}{u}',
    'history_insight': 'Insight',
    'history_recent': 'Recent entries',
    'history_show_less': 'Show less',
    'history_show_all': 'Show all ({n})',
    'chart_empty': 'No chart data yet.',

    // --- result ---
    'result_title': 'BMI Result',
    'result_tips': 'Tips for you',
    'result_saving': 'Saving…',
    'result_save': 'Save to history',
    'result_sharing': 'Sharing…',
    'result_share': 'Share',
    'result_healthy_range': 'Healthy weight range',
    'result_for_height': 'For height {h}: {lo} – {hi}',
    'result_below': "You're {w} — {d} below the healthy range.",
    'result_above': "You're {w} — {d} above the healthy range.",
    'result_inside': "You're {w} — inside the healthy range ✓",
    'result_already_target': 'Already the target',
    'result_set_target': 'Set as target',
    'result_target_saved': 'Target {t} saved — check the Streak tab.',
    'result_saved': 'Saved to history.',
    'result_share_fail': "Couldn't create the image.",
    'result_share_text': 'My BMI is {bmi} ({cat}) — calculated with Raga',

    // --- health ---
    'health_title': 'Health',
    'activity_minimal': 'Minimal',
    'activity_light': 'Light',
    'activity_moderate': 'Moderate',
    'activity_active': 'Active',
    'health_calorie_need': 'Daily calorie needs',
    'health_bmr_line': 'BMR {bmr} kcal/day · Mifflin-St Jeor equation',
    'goal_lose': 'Lose',
    'goal_maintain': 'Maintain',
    'goal_gain': 'Gain',
    'health_ideal': 'Ideal weight',
    'health_you': 'You: {v} {u}',
    'profile_line': '{gender} · {n} yrs · {h}',

    // --- streak ---
    'streak_title': 'Streak',
    'streak_done': 'Weighed in this week ✓',
    'streak_todo': 'Weigh in this week to keep the streak going',
    'streak_goals': 'Goals',
    'streak_goal_weight': 'Goal weight',
    'streak_no_goal': 'No goal yet — tap to set',
    'streak_goal_maintain': 'Maintain {g}',
    'streak_goal_down': 'Down to {g}',
    'streak_goal_up': 'Up to {g}',
    'streak_last8': 'Last 8 weeks',
    'streak_all_done': 'All milestones reached!',
    'streak_next': 'Next milestone: {w}',
    'streak_togo': '{w} to go',
    'streak_keep': 'So consistent — keep it up!',
    'streak_dialog_stay': 'Stay at {w}',
    'streak_dialog_togo': '{s}{w} to go',
    'streak_save_goal': 'Save goal',
    'streak_delete_goal': 'Delete goal',

    // --- onboarding ---
    'ob1_title': "Let's get acquainted",
    'ob1_sub': 'So Raga can greet you and calculate accurately.',
    'ob1_name': 'Nickname',
    'ob1_age': 'Age',
    'ob1_gender': 'Gender',
    'ob2_title': 'Your measurements',
    'ob2_sub': 'Used to calculate your starting BMI.',
    'ob2_bmi': 'Your starting BMI',
    'ob_optional': 'OPTIONAL',
    'ob3_title': 'Have a weight goal?',
    'ob3_sub': 'Set it now or later in Profile. You can skip.',
    'ob3_hint_stay': 'Stay at {w}',
    'ob3_hint_diff': 'Now {w} · difference {s}{d} {u}',
    'ob3_pace': 'Pace per week',
    'ob3_eta': 'Estimated date',
    'ob3_eta_weeks': '±{w} · {date}',
    'ob4_title': 'Weigh-in schedule',
    'ob4_sub': 'Pick days and time; Raga will remind you. You can skip.',
    'ob4_time': 'Reminder time',
    'ob4_summary': 'Summary',
    'ob4_note': 'You can change this anytime in Profile.',
    'ob_done': 'Done',
    'ob_skip': 'Skip for now',
    'ob_need_name': 'Enter your nickname first',
    'ob_notif_off': 'Turn on notifications in system settings first',
    'ob_exact_off': 'Enable "Alarms & reminders" in system settings, '
        'then set the reminder from Profile.',

    // --- profile sheet ---
    'sheet_edit': 'Edit profile',
    'sheet_new': 'New profile',
    'sheet_name_hint': 'Name',
    'sheet_gender': 'Gender',
    'sheet_age': 'Age',
    'sheet_years': 'years',
    'sheet_height': 'Height',

    // --- profile screen ---
    'profile_title': 'Profile',
    'profile_longpress_hint': 'Long-press a profile chip to delete it',
    'profile_settings': 'Settings',
    'profile_units': 'Units',
    'profile_theme': 'Theme',
    'theme_dark': 'Dark',
    'theme_light': 'Light',
    'profile_reminder': 'Reminder',
    'profile_reminder_on': 'Weekly weigh-in reminder on',
    'profile_reminder_off': 'Weekly weigh-in reminder off',
    'profile_backup': 'Backup',
    'profile_others': 'More',
    'profile_status': 'Status',
    'profile_pending': '{n} entries waiting to upload.',
    'profile_backup_code': 'Backup code',
    'profile_code_not_ready': '(not ready)',
    'profile_copy_code': 'Copy code',
    'profile_code_copied': 'Backup code copied',
    'profile_sync_now': 'Sync now',
    'profile_restore': 'Restore from code',
    'profile_backup_note':
        'Stored safely in your private cloud. No account — just works.',
    'profile_devmode': 'Developer mode',
    'profile_dev_on': 'Logs, test notifications, server info',
    'profile_dev_off': 'Extra tools for debugging',
    'profile_test_notif': 'Send test notification',
    'profile_test_notif_sub': 'Send one now',
    'profile_alarms': 'Registered alarms',
    'profile_alarms_sub': 'What the OS actually registered',
    'profile_log': 'Log',
    'profile_log_sub': 'Diagnostics & debugging',
    'profile_wipe': 'Delete all data',
    'profile_version': 'App version',
    'profile_delete_title': 'Delete profile?',
    'profile_delete_body':
        '{name} and their history will be gone forever.',
    'profile_delete_last': "Can't delete the last profile",
    'profile_replace_title': 'Replace everything?',
    'profile_replace_body': 'All profiles and history on this phone will '
        'be replaced with the backup data. This cannot be undone.',
    'profile_replace_ok': 'Restore',
    'profile_restored': 'Backup restored — welcome back.',
    'profile_restore_fail': 'Code not found or cloud unreachable. '
        'Check the code and try again.',
    'profile_test_sent': 'Test notification sent',
    'profile_test_fail':
        "Couldn't show the notification — check permissions",
    'profile_sched_title': 'Reminder schedule',
    'profile_next': 'Next: {t}',
    'profile_pick_day': 'Pick at least one day',
    'profile_today': 'Today',
    'profile_tomorrow': 'Tomorrow',
    'profile_arm_notif': 'Turn on notifications in system settings first',
    'profile_arm_exact': 'Enable "Alarms & reminders" in system settings, '
        'then turn the reminder back on.',
    'profile_arm_ok': 'Weekly reminder on',
    'profile_arm_late': 'Reminder on, but exact alarms are off — it may '
        'run late. Allow "Alarms & reminders" in system settings for '
        'on-time delivery.',
    'profile_wipe_body':
        'History and profiles on this device will be gone forever.',
    'profile_wiped': 'All data deleted',
    'profile_alarms_empty': 'No alarms registered with the OS.',
    'alarms_no_title': '(no title)',

    // --- restore choice (merge vs replace) ---
    'profile_restore_mode_title': 'Restore from code',
    'profile_restore_mode_body': 'This code matches. Merge it with the '
        'data already on this phone, or replace everything?',
    'profile_merge': 'Merge',
    'profile_merged': '{n} new entries merged from backup',
    'profile_merge_empty':
        'No new entries in the backup — your data is already complete.',

    // --- account: optional Google login (auth_service.dart) ---
    'auth_title': 'Account',
    'auth_anon_note': 'You are using Raga without logging in — everything '
        'still works. Sign in with Google if you want your data to follow '
        'your account on other phones.',
    'auth_sign_in_google': 'Sign in with Google',
    'auth_sign_in_cancelled': 'Sign-in cancelled',
    'auth_not_configured': 'Google sign-in is not set up in this build',
    'auth_sign_in_failed': 'Sign-in failed: {e}',
    'auth_migrated': '{n} entries moved to your account',
    'auth_welcome': 'Welcome, {name}!',
    'auth_welcome_back': 'Welcome back!',
    'auth_default_name': 'Google user',
    'auth_edit_name': 'Edit name',
    'auth_name_title': 'Display name',
    'auth_name_hint': 'Display name',
    'auth_name_updated': 'Name updated',
    'auth_name_failed': "Couldn't save the name",
    'auth_change_photo': 'Change photo',
    'auth_uploading_photo': 'Uploading photo…',
    'auth_photo_updated': 'Profile photo updated',
    'auth_photo_failed': 'Failed to upload photo',
    'auth_sign_out': 'Sign out',
    'auth_sign_out_title': 'Sign out of your account?',
    'auth_sign_out_body': 'The login session ends. Data on this phone '
        'stays — sign in again anytime to sync it.',
    'auth_signed_out': "You're signed out",
    'auth_sync_offer_title': 'Sync your account data?',
    'auth_sync_offer_body':
        'This account has {n} entries in the cloud. Merge them into this phone?',
    'auth_sync_merge': 'Merge',
    'auth_sync_later': 'Later',
    'auth_merged': '{n} cloud entries merged',
    'auth_merge_empty': "Already in sync — nothing new.",
    'auth_merge_failed': "Couldn't fetch cloud data",

    // --- log viewer ---
    'log_hint': 'long-press a line to copy',
    'log_copy_all': 'Copy all',
    'log_copied_line': 'Line copied',
    'log_copied_all': 'All logs copied',

    // --- reminder summary (bmi.dart) ---
    'rem_off': 'Off',
    'rem_every_day': 'Every day · {t}',
    'rem_per_week': '{n}× a week · {days} · {t}',

    // --- span labels (bmi.dart) ---
    'span_today': 'today',
    'span_days': '{n} days',
    'span_weeks': '{n} weeks',
    'span_months': '{n} months',

    // --- weight insight (bmi.dart) ---
    'insight_empty': 'Not enough data in this range — weigh in at least '
        'twice to see the trend.',
    'insight_stable': 'Steady at {w} for {span} — keep it up.',
    'insight_down': 'Down {w} over {span}.',
    'insight_up': 'Up {w} over {span}.',
    'insight_rate_ok': ' Rate ±{r}/week — within a healthy range.',
    'insight_rate_fast': ' Rate ±{r}/week — above the general guideline '
        '({lim}/week); consider talking to a nutritionist.',
    'insight_rate': ' Rate ±{r}/week.',
    'insight_goal_done': ' Target {w} reached — keep it up!',
    'insight_goal_left': ' {w} left to reach your goal.',
    'insight_goal_over': ' {w} under target.',

    // --- sync status (cloud_sync.dart) ---
    'sync_not_configured': 'Not set up',
    'sync_no_connect': "Couldn't connect",
    'sync_ok': 'Connected — everything is synced',
    'sync_pending': '{n} entries waiting to upload',
  },
};

/// Localized string for the current locale in [context], with {name}
/// placeholders filled from [args].
String tx(BuildContext context, String key, [Map<String, Object>? args]) {
  return txl(AppState.of(context).locale, key, args);
}

/// Same as [tx] but takes the locale directly (for non-widget code).
String txl(String locale, String key, [Map<String, Object>? args]) {
  final id = _strings['id']!;
  var s = _strings[locale]?[key] ?? id[key] ?? key;
  if (args != null) {
    for (final e in args.entries) {
      s = s.replaceAll('{${e.key}}', '${e.value}');
    }
  }
  return s;
}

/// "N minggu" / "N week(s)" — English needs the singular.
String weeksN(String locale, int n) =>
    locale == 'en' ? '$n ${n == 1 ? 'week' : 'weeks'}' : '$n minggu';
