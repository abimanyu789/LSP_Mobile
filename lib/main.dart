// ============================================================
// AGENDA NUSANTARA - Aplikasi Todo-List untuk Sertifikasi
// Kompetensi Mobile Developer
//
// Developer: [Nama Anda]
// NIM: [NIM Anda]
// Framework: Flutter (Dart)
// Database: SQLite (sqflite)
// Tanggal: 2026
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Entry point aplikasi Flutter
/// Fungsi main() adalah titik masuk pertama yang dijalankan
void main() async {
  // Pastikan Flutter binding sudah diinisialisasi sebelum memanggil API native
  // WAJIB dipanggil sebelum await di main() dan sebelum WidgetsFlutterBinding.ensureInitialized()
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale data untuk format tanggal bahasa Indonesia
  // Diperlukan oleh package intl untuk DateFormat dengan locale 'id_ID'
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi kredensial default (username: 'user', password: 'user')
  // jika belum pernah diset sebelumnya
  final authService = AuthService();
  await authService.initDefaultCredentials();

  // Cek apakah user sudah login sebelumnya (persistent session)
  final isLoggedIn = await authService.isLoggedIn();

  // Paksa orientasi portrait saja (sesuai spesifikasi aplikasi mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Jalankan aplikasi Flutter
  // isLoggedIn menentukan halaman awal: HomeScreen atau LoginScreen
  runApp(AgendaNusantaraApp(isLoggedIn: isLoggedIn));
}

/// Widget root aplikasi Agenda Nusantara
///
/// Kelas ini merupakan widget pertama yang dirender oleh Flutter
/// Bertugas mengkonfigurasi:
/// - Tema aplikasi (warna, font, komponen style)
/// - Halaman awal berdasarkan status login
/// - Konfigurasi MaterialApp
class AgendaNusantaraApp extends StatelessWidget {
  /// Status login untuk menentukan halaman awal
  final bool isLoggedIn;

  const AgendaNusantaraApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ---- Konfigurasi Aplikasi ----

      /// Nama aplikasi (ditampilkan di task switcher Android)
      title: 'Agenda Nusantara',

      /// Sembunyikan banner "Debug" di pojok kanan atas
      debugShowCheckedModeBanner: false,

      // ---- Konfigurasi Tema ----

      /// Terapkan tema yang sudah dikonfigurasi di AppTheme
      /// Semua warna, font, dan komponen mengikuti design system
      theme: AppTheme.theme,

      // ---- Halaman Awal ----

      /// Tentukan halaman awal berdasarkan status login:
      /// - Jika sudah login → tampilkan HomeScreen (beranda)
      /// - Jika belum login → tampilkan LoginScreen (login)
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),

      // ---- Konfigurasi Rute ----
      // Named routes untuk navigasi yang lebih terstruktur
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
