import 'package:flutter/material.dart';

/// Kelas yang mendefinisikan semua konstanta tema dan warna aplikasi
/// Menggunakan pendekatan centralized design system untuk konsistensi UI
/// Setiap warna, ukuran, dan style didefinisikan di satu tempat
class AppTheme {
  // ============================================================
  // COLOR PALETTE - Palet warna utama aplikasi
  // ============================================================

  /// Warna primer - Biru tua modern untuk elemen utama (AppBar, tombol)
  static const Color primaryColor = Color(0xFF1565C0);

  /// Warna primer yang lebih gelap - untuk hover/pressed state
  static const Color primaryDark = Color(0xFF003C8F);

  /// Warna sekunder - Emas/amber untuk aksen dan highlight
  static const Color accentColor = Color(0xFFFFC107);

  /// Warna latar belakang halaman utama - putih keabuan yang bersih
  static const Color backgroundColor = Color(0xFFF5F7FA);

  /// Warna permukaan kartu dan container
  static const Color surfaceColor = Color(0xFFFFFFFF);

  /// Warna teks utama - hitam pekat
  static const Color textPrimary = Color(0xFF1A1A2E);

  /// Warna teks sekunder - abu-abu untuk teks subinfo
  static const Color textSecondary = Color(0xFF6B7280);

  // ============================================================
  // TASK TYPE COLORS - Warna berdasarkan jenis tugas
  // ============================================================

  /// Warna untuk tugas PENTING - merah (sesuai spesifikasi soal)
  static const Color colorPenting = Color(0xFFE53935);

  /// Warna latar belakang untuk badge tugas penting (lebih transparan)
  static const Color colorPentingLight = Color(0xFFFFEBEE);

  /// Warna untuk tugas BIASA - hijau (sesuai spesifikasi soal)
  static const Color colorBiasa = Color(0xFF43A047);

  /// Warna latar belakang untuk badge tugas biasa (lebih transparan)
  static const Color colorBiasaLight = Color(0xFFE8F5E9);

  /// Warna untuk tugas yang SUDAH SELESAI - abu-abu
  static const Color colorCompleted = Color(0xFF9E9E9E);

  // ============================================================
  // STATUS COLORS - Warna untuk status dan feedback
  // ============================================================

  /// Warna sukses (operasi berhasil)
  static const Color successColor = Color(0xFF4CAF50);

  /// Warna error/peringatan
  static const Color errorColor = Color(0xFFF44336);

  /// Warna warning
  static const Color warningColor = Color(0xFFFF9800);

  /// Warna info
  static const Color infoColor = Color(0xFF2196F3);

  // ============================================================
  // SPACING - Ukuran padding dan margin yang konsisten
  // ============================================================

  /// Padding sangat kecil - 4px
  static const double spacingXS = 4.0;

  /// Padding kecil - 8px
  static const double spacingSM = 8.0;

  /// Padding medium - 16px (standar Material Design)
  static const double spacingMD = 16.0;

  /// Padding besar - 24px
  static const double spacingLG = 24.0;

  /// Padding sangat besar - 32px
  static const double spacingXL = 32.0;

  // ============================================================
  // BORDER RADIUS - Kelengkungan sudut elemen UI
  // ============================================================

  /// Radius kecil untuk chip dan badge - 8px
  static const double radiusSM = 8.0;

  /// Radius medium untuk kartu - 12px
  static const double radiusMD = 12.0;

  /// Radius besar untuk bottom sheet dan modal - 20px
  static const double radiusLG = 20.0;

  /// Radius lingkaran penuh - untuk avatar dan FAB
  static const double radiusCircle = 100.0;

  // ============================================================
  // TEXT STYLES - Gaya teks yang konsisten
  // ============================================================

  /// Style untuk judul halaman (headline)
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5, // Sedikit rapat untuk tampilan modern
  );

  /// Style untuk subjudul/section title
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Style untuk teks body standar
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  /// Style untuk teks kecil/caption
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  // ============================================================
  // MATERIAL THEME - Konfigurasi ThemeData Flutter
  // ============================================================

  /// Membuat ThemeData lengkap untuk aplikasi
  /// Dipanggil di MaterialApp untuk mengaplikasikan tema secara global
  static ThemeData get theme {
    return ThemeData(
      // ---- Color Scheme ----
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
      ),

      // ---- App Bar Theme ----
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0, // Flat AppBar untuk tampilan modern
        centerTitle: false, // Judul di kiri untuk Android
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // ---- Card Theme ----
      cardTheme: CardThemeData(
        elevation: 2, // Bayangan ringan untuk depth
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        color: surfaceColor,
        margin: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingSM,
        ),
      ),

      // ---- Elevated Button Theme ----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ---- Input Decoration Theme ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingMD,
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),

      // ---- Checkbox Theme ----
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return successColor;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ---- FAB Theme ----
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // ---- Bottom Navigation Bar Theme ----
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed, // Semua item selalu tampil
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ---- Scaffold Background Color ----
      scaffoldBackgroundColor: backgroundColor,

      useMaterial3: true, // Gunakan Material Design 3 (terbaru)
    );
  }

  // ============================================================
  // HELPER METHODS - Metode bantuan untuk styling
  // ============================================================

  /// Mendapatkan warna berdasarkan jenis tugas
  /// [type] - 'penting' atau 'biasa'
  static Color getTaskColor(String type) {
    return type == 'penting' ? colorPenting : colorBiasa;
  }

  /// Mendapatkan warna latar belakang berdasarkan jenis tugas
  static Color getTaskLightColor(String type) {
    return type == 'penting' ? colorPentingLight : colorBiasaLight;
  }

  /// Membuat BoxDecoration dengan gradient vertikal
  static BoxDecoration gradientDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, primaryDark],
      ),
    );
  }
}
