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
    // --- Arena -------------------------------------------------------
    'arena_title': 'Arena',
    'arena_tab_board': 'Leaderboard',
    'arena_tab_wrapped': 'Wrapped',
    'arena_login_title': 'Login dulu buat masuk Arena',
    'arena_login_body':
        'Leaderboard komunitas dan Raga Wrapped cuma tersedia buat yang login.',
    'arena_login_button': 'Masuk dengan Google',
    // --- Leaderboard --------------------------------------------------
    'lb_tab_loss': '% Susut',
    'lb_tab_streak': 'Streak',
    'lb_opt_in': 'Ikut leaderboard',
    'lb_opt_in_on': 'Kamu ikut leaderboard minggu ini 🎉',
    'lb_opt_in_body':
        'Namamu, fotomu, dan angkamu bakal kelihatan peserta lain. Data berat mentahmu tetap privat.',
    'lb_empty': 'Belum ada peserta minggu ini. Jadilah yang pertama!',
    'lb_you': 'Kamu',
    'lb_min_records':
        'Butuh minimal 2x timbang minggu ini buat masuk papan % Susut.',
    // --- Wrapped ------------------------------------------------------
    'wrapped_title': 'Raga Wrapped',
    'wrapped_view': 'Lihat Wrapped',
    'wrapped_unlocks': 'Wrapped baru kebuka {d} hari lagi',
    'wrapped_unlocks_one': 'Wrapped baru kebuka besok',
    'wrapped_empty_title': 'Minggu lalu sepi',
    'wrapped_empty_body':
        'Nggak ada timbangan tercatat minggu lalu. Minggu ini gas lagi!',
    'wrapped_cover_sub': 'Rekap mingguanmu',
    'wrapped_logs': 'Kamu nimbang {n} kali minggu ini',
    'wrapped_logs_one': 'Kamu nimbang 1 kali minggu ini',
    'wrapped_logs_vs': '{d} dari minggu lalu',
    'wrapped_delta_down': 'Turun {kg} kg ({pct}%)',
    'wrapped_delta_up': 'Naik {kg} kg ({pct}%)',
    'wrapped_delta_flat': 'Beratmu stabil minggu ini',
    'wrapped_delta_need': 'Timbang minimal 2x biar kebaca trennya',
    'wrapped_streak': '{n} minggu beruntun',
    'wrapped_streak_one': '1 minggu beruntun',
    'wrapped_badge_title': 'Badge minggu ini',
    'wrapped_badge_konsisten': 'Si Konsisten',
    'wrapped_badge_konsisten_d': 'Nimbang 5 hari atau lebih. Disiplin!',
    'wrapped_badge_pejuang': 'Pejuang Susut',
    'wrapped_badge_pejuang_d': 'Turun 1 kg atau lebih dalam seminggu.',
    'wrapped_badge_maraton': 'Maratonian',
    'wrapped_badge_maraton_d': 'Streak 8 minggu. Bukan kaleng-kaleng.',
    'wrapped_badge_comeback': 'Comeback Kid',
    'wrapped_badge_comeback_d': 'Balik lagi setelah 2 minggu hilang.',
    'wrapped_badge_penjelajah': 'Penjelajah Data',
    'wrapped_badge_penjelajah_d': 'Setiap perjalanan dimulai dari satu timbangan.',
    'wrapped_closing': 'Sampai jumpa Senin depan. Tetap semangat! 💪',
    'wrapped_preview': 'Preview Wrapped (dev)',
    'wrapped_preview_empty': 'Belum ada timbangan dalam 12 minggu terakhir',
    'lb_cap_note':
        'Susut maksimal yang dihitung 3%/minggu — biar fair buat semua.',
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

    // --- detak (companion) ---
    'detak_title': 'Detak',
    'detak_subtitle': 'Teman perjalananmu',
    'detak_dialog_body':
        'Ketuk untuk membuka halaman Detak — tempat ngobrol, melihat kedekatan, dan mengatur penampilan Detak.',
    'detak_dialog_open': 'Buka halaman Detak',
    'detak_mood_halo': 'Halo',
    'detak_mood_senang': 'Senang',
    'detak_mood_semangat': 'Semangat',
    'detak_mood_ngantuk': 'Ngantuk',
    'detak_mood_dukung': 'Dukung',
    'detak_mood_bangga': 'Bangga',
    'detak_growth': 'Tahap pertumbuhan',
    'detak_stage_kuncup': 'Kuncup',
    'detak_stage_dua': 'Dua daun',
    'detak_stage_rimbun': 'Rimbun',
    'detak_stage_berbunga': 'Berbunga',
    'detak_growth_hint': 'Catat berat {n}× lagi, daun {name} jadi {stage}',
    'detak_growth_max': '{name} sudah mekar sempurna di Lv. {m}!',
    'detak_closeness': 'Kedekatan',
    'detak_closeness_hint': 'Catat berat {n}× lagi untuk naik ke Lv. {m}',
    'detak_today': 'Hari ini bareng Detak',
    'detak_quest_log': 'Catat berat hari ini',
    'detak_quest_trend': 'Lihat tren minggu ini',
    'detak_quest_reward': '+1 kedekatan',
    'detak_change_style': 'Ubah penampilan',
    'detak_recent': 'Reaksi terbaru',
    'detak_recent_today': 'Hari ini',
    'detak_recent_yesterday': 'Kemarin',
    'detak_style_title': 'Penampilan Detak',
    'detak_style_subtitle': 'Bikin dia jadi milikmu',
    'detak_name_label': 'Nama Detak',
    'detak_color': 'Warna',
    'detak_accessory': 'Aksesori',
    'detak_acc_none': 'Polos',
    'detak_acc_kacamata': 'Kacamata',
    'detak_acc_pita': 'Pita',
    'detak_notif': 'Detak di notifikasi',
    'detak_calm': 'Mode tenang (tanpa animasi)',
    'detak_gallery_title': 'Maskot · Detak',
    'detak_gallery_subtitle': 'Raga Companion, 6 ekspresi',
    'detak_expr_halo_d': 'Buka app, belum ada aktivitas baru',
    'detak_expr_senang_d': 'Mencatat berat atau menimbang sesuai jadwal',
    'detak_expr_semangat_d': 'Streak 7 hari atau naik level',
    'detak_expr_ngantuk_d': '3 hari tidak membuka app',
    'detak_expr_dukung_d': 'Jadwal terlewat. Tanpa menyalahkan',
    'detak_expr_bangga_d': 'Target berat badan tercapai',
    'detak_note': 'Jarum di dada = energi Detak. Detak bereaksi pada '
        'kebiasaanmu, bukan angka timbangan. Idle: napas 3 dtk, kedip tiap '
        '5 dtk, daun bergoyang saat disentuh.',
    // message variants (engine picks one per event)
    'detak_msg_greet_0': 'Hai! Detak di sini. Hari ini mau ngapain dulu?',
    'detak_msg_greet_1': 'Selamat datang! Yuk bikin hari ini berarti.',
    'detak_msg_comeback3_0':
        'Eh, kamu balik! Kangen nih. Mulai pelan-pelan lagi yuk.',
    'detak_msg_comeback3_1':
        'Tiga hari nggak ketemu... yuk lanjut lagi, santai aja.',
    'detak_msg_comeback7_0': 'Aku kangen banget! Seminggu lebih nggak '
        'ketemu. Yuk mulai lagi bareng-bareng.',
    'detak_msg_comeback7_1': 'Akhirnya balik juga! Nggak apa-apa jeda, '
        'yang penting balik lagi.',
    'detak_msg_comeback14_0':
        'Welcome back! Kita mulai lagi pelan-pelan, yuk.',
    'detak_msg_comeback14_1': 'Lama banget nggak ketemu... Detak kangen! '
        'Yuk mulai lagi, nggak perlu sempurna.',
    'detak_msg_record_0': 'Catat! Konsisten itu keren.',
    'detak_msg_record_1': 'Nice! Satu langkah lagi menuju tujuanmu.',
    'detak_msg_record_2': 'Berat hari ini aman. Kamu hebat!',
    'detak_msg_trend_0': '+1 kedekatan! Makasih udah mampir lihat tren.',
    'detak_msg_trend_1': 'Trennya dicek, kedekatan nambah. Mantap!',
    'detak_msg_streak_0': '{n} hari berturut-turut! Daunku makin rimbun.',
    'detak_msg_streak_1': 'Streak {n} hari! Kita kompak banget sih.',
    'detak_msg_levelup_0': 'Naik ke Lv. {n}! Kita tumbuh bareng-bareng.',
    'detak_msg_levelup_1': 'Lv. {n} tercapai! Daunku makin {stage}.',
    'detak_msg_goal_0': 'TARGET TERCAPAI! Detak bangga banget sama kamu!',
    'detak_msg_goal_1': 'Gol tercapai! Kamu luar biasa. Pertahankan ya!',
    'detak_msg_missed_0':
        'Kemarin kelewat ya? Nggak apa-apa, hari ini kita lanjut.',
    'detak_msg_missed_1':
        'Jadwal kemarin terlewat, besok lagi ya. Santai.',
    'detak_msg_tap_0': 'Hehe, geli!',
    'detak_msg_tap_1': 'Ada apa? Detak di sini kok.',
    'detak_msg_tap_2': 'Tos! Semangat hari ini!',
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
    // --- Arena -------------------------------------------------------
    'arena_title': 'Arena',
    'arena_tab_board': 'Leaderboard',
    'arena_tab_wrapped': 'Wrapped',
    'arena_login_title': 'Log in to enter the Arena',
    'arena_login_body':
        'The community leaderboard and Raga Wrapped are for logged-in users.',
    'arena_login_button': 'Sign in with Google',
    // --- Leaderboard --------------------------------------------------
    'lb_tab_loss': '% Lost',
    'lb_tab_streak': 'Streak',
    'lb_opt_in': 'Join the leaderboard',
    'lb_opt_in_on': "You're on this week's board 🎉",
    'lb_opt_in_body':
        'Your name, photo and score will be visible to other contenders. Your raw weight data stays private.',
    'lb_empty': 'No contenders yet this week. Be the first!',
    'lb_you': 'You',
    'lb_min_records':
        'You need at least 2 weigh-ins this week to rank on the % board.',
    // --- Wrapped ------------------------------------------------------
    'wrapped_title': 'Raga Wrapped',
    'wrapped_view': 'View Wrapped',
    'wrapped_unlocks': 'New Wrapped unlocks in {d} days',
    'wrapped_unlocks_one': 'New Wrapped unlocks tomorrow',
    'wrapped_empty_title': 'Quiet week',
    'wrapped_empty_body':
        'No weigh-ins logged last week. Go get this week!',
    'wrapped_cover_sub': 'Your weekly recap',
    'wrapped_logs': 'You weighed in {n} times this week',
    'wrapped_logs_one': 'You weighed in once this week',
    'wrapped_logs_vs': '{d} vs last week',
    'wrapped_delta_down': 'Down {kg} kg ({pct}%)',
    'wrapped_delta_up': 'Up {kg} kg ({pct}%)',
    'wrapped_delta_flat': 'Your weight held steady this week',
    'wrapped_delta_need': 'Weigh in at least twice to see your trend',
    'wrapped_streak': '{n}-week streak',
    'wrapped_streak_one': '1-week streak',
    'wrapped_badge_title': "This week's badge",
    'wrapped_badge_konsisten': 'Mr. Consistent',
    'wrapped_badge_konsisten_d': 'Weighed in 5+ days. Disciplined!',
    'wrapped_badge_pejuang': 'Shrink Fighter',
    'wrapped_badge_pejuang_d': 'Lost 1 kg or more in a week.',
    'wrapped_badge_maraton': 'Marathoner',
    'wrapped_badge_maraton_d': '8-week streak. No joke.',
    'wrapped_badge_comeback': 'Comeback Kid',
    'wrapped_badge_comeback_d': 'Back after 2 weeks away.',
    'wrapped_badge_penjelajah': 'Data Explorer',
    'wrapped_badge_penjelajah_d': 'Every journey starts with one weigh-in.',
    'wrapped_closing': 'See you next Monday. Keep going! 💪',
    'wrapped_preview': 'Preview Wrapped (dev)',
    'wrapped_preview_empty': 'No weigh-ins in the last 12 weeks',
    'lb_cap_note':
        'Losses are capped at 3%/week to keep it fair for everyone.',
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

    // --- detak (companion) ---
    'detak_title': 'Detak',
    'detak_subtitle': 'Your journey buddy',
    'detak_dialog_body':
        "Tap to open Detak's page — a place to hang out, check your closeness, and style Detak.",
    'detak_dialog_open': "Open Detak's page",
    'detak_mood_halo': 'Hello',
    'detak_mood_senang': 'Happy',
    'detak_mood_semangat': 'Fired up',
    'detak_mood_ngantuk': 'Sleepy',
    'detak_mood_dukung': 'Support',
    'detak_mood_bangga': 'Proud',
    'detak_growth': 'Growth stages',
    'detak_stage_kuncup': 'Sprout',
    'detak_stage_dua': 'Two leaves',
    'detak_stage_rimbun': 'Lush',
    'detak_stage_berbunga': 'Blooming',
    'detak_growth_hint':
        "Log weight {n}× more and {name}'s leaves turn {stage}",
    'detak_growth_max': '{name} is in full bloom at Lv. {m}!',
    'detak_closeness': 'Closeness',
    'detak_closeness_hint': 'Log weight {n}× more to reach Lv. {m}',
    'detak_today': 'Today with Detak',
    'detak_quest_log': "Log today's weight",
    'detak_quest_trend': "Check this week's trend",
    'detak_quest_reward': '+1 closeness',
    'detak_change_style': 'Change appearance',
    'detak_recent': 'Recent reactions',
    'detak_recent_today': 'Today',
    'detak_recent_yesterday': 'Yesterday',
    'detak_style_title': "Detak's appearance",
    'detak_style_subtitle': 'Make them truly yours',
    'detak_name_label': "Detak's name",
    'detak_color': 'Color',
    'detak_accessory': 'Accessories',
    'detak_acc_none': 'None',
    'detak_acc_kacamata': 'Glasses',
    'detak_acc_pita': 'Bow',
    'detak_notif': 'Detak in notifications',
    'detak_calm': 'Calm mode (no animation)',
    'detak_gallery_title': 'Mascot · Detak',
    'detak_gallery_subtitle': 'Raga Companion, 6 expressions',
    'detak_expr_halo_d': 'Opening the app, no new activity yet',
    'detak_expr_senang_d': 'Logging weight or weighing on schedule',
    'detak_expr_semangat_d': '7-day streak or level up',
    'detak_expr_ngantuk_d': 'App unopened for 3 days',
    'detak_expr_dukung_d': 'Schedule missed. No blame',
    'detak_expr_bangga_d': 'Weight goal reached',
    'detak_note': "The chest needle = Detak's energy. Detak reacts to "
        'your habits, not the scale number. Idle: 3s breath, blink every '
        '5s, leaves sway when touched.',
    // message variants (engine picks one per event)
    'detak_msg_greet_0': "Hi! Detak here. What shall we do today?",
    'detak_msg_greet_1': "Welcome! Let's make today count.",
    'detak_msg_comeback3_0':
        "Oh, you're back! Missed you. Let's ease back in.",
    'detak_msg_comeback3_1':
        "Three days apart... let's pick it up again, nice and easy.",
    'detak_msg_comeback7_0': 'I missed you so much! Over a week apart. '
        "Let's start again together.",
    'detak_msg_comeback7_1': 'Finally back! Pausing is fine — coming '
        'back is what counts.',
    'detak_msg_comeback14_0':
        "Welcome back! Let's start again slowly, shall we?",
    'detak_msg_comeback14_1': "It's been so long... Detak missed you! "
        "Let's restart — no need to be perfect.",
    'detak_msg_record_0': 'Logged! Consistency is cool.',
    'detak_msg_record_1': "Nice! One step closer to your goal.",
    'detak_msg_record_2': "Today's weight is in. You're doing great!",
    'detak_msg_trend_0': '+1 closeness! Thanks for checking the trend.',
    'detak_msg_trend_1': 'Trend checked, closeness up. Awesome!',
    'detak_msg_streak_0': '{n} days in a row! My leaves are getting lusher.',
    'detak_msg_streak_1': "{n}-day streak! We're so in sync.",
    'detak_msg_levelup_0': "Up to Lv. {n}! We're growing together.",
    'detak_msg_levelup_1': 'Lv. {n} reached! My leaves are getting {stage}.',
    'detak_msg_goal_0': 'GOAL REACHED! Detak is so proud of you!',
    'detak_msg_goal_1': "Goal smashed! You're amazing. Keep it up!",
    'detak_msg_missed_0':
        'Missed yesterday? No worries, we continue today.',
    'detak_msg_missed_1':
        "Yesterday's schedule slipped — tomorrow again, okay? Easy does it.",
    'detak_msg_tap_0': 'Hehe, tickles!',
    'detak_msg_tap_1': "What's up? Detak's right here.",
    'detak_msg_tap_2': "High five! Let's crush today!",
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
