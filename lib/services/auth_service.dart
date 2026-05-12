import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola autentikasi pengguna
/// Menggunakan SharedPreferences untuk menyimpan kredensial secara lokal
/// Data disimpan secara terenkripsi di storage perangkat (melalui SharedPreferences)
class AuthService {
  // ============================================================
  // KEY CONSTANTS - Kunci untuk SharedPreferences
  // ============================================================

  /// Kunci untuk menyimpan username di SharedPreferences
  static const String _keyUsername = 'auth_username';

  /// Kunci untuk menyimpan password di SharedPreferences
  static const String _keyPassword = 'auth_password';

  /// Kunci untuk menyimpan status login (apakah user sedang login)
  static const String _keyIsLoggedIn = 'auth_is_logged_in';

  // ============================================================
  // DEFAULT CREDENTIALS - Kredensial default aplikasi
  // ============================================================

  /// Username default yang digunakan saat pertama kali install
  static const String defaultUsername = 'user';

  /// Password default yang digunakan saat pertama kali install
  static const String defaultPassword = 'user';

  // ============================================================
  // INITIALIZATION - Inisialisasi dan setup kredensial default
  // ============================================================

  /// Menginisialisasi kredensial default jika belum ada
  /// Dipanggil saat aplikasi pertama kali dijalankan
  Future<void> initDefaultCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    // Cek apakah username sudah pernah diset
    // Jika belum, set dengan nilai default
    if (!prefs.containsKey(_keyUsername)) {
      await prefs.setString(_keyUsername, defaultUsername);
    }

    if (!prefs.containsKey(_keyPassword)) {
      await prefs.setString(_keyPassword, defaultPassword);
    }
  }

  // ============================================================
  // AUTH OPERATIONS - Operasi autentikasi
  // ============================================================

  /// Memvalidasi kredensial login pengguna
  /// Mengembalikan true jika username dan password cocok
  /// Mengembalikan false jika kredensial salah
  Future<bool> login(String username, String password) async {
    // Validasi input tidak boleh kosong sebelum cek database
    if (username.trim().isEmpty || password.trim().isEmpty) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    // Ambil kredensial yang tersimpan (gunakan default jika belum diset)
    final storedUsername =
        prefs.getString(_keyUsername) ?? defaultUsername;
    final storedPassword =
        prefs.getString(_keyPassword) ?? defaultPassword;

    // Bandingkan kredensial yang diinput dengan yang tersimpan
    // trim() untuk menghapus spasi di awal/akhir input
    final isValid =
        username.trim() == storedUsername &&
        password.trim() == storedPassword;

    // Simpan status login jika berhasil
    if (isValid) {
      await prefs.setBool(_keyIsLoggedIn, true);
    }

    return isValid;
  }

  /// Melakukan logout - menghapus status login
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  /// Mengecek apakah pengguna sedang dalam status login
  /// Digunakan untuk menentukan halaman awal aplikasi
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Mengambil username yang sedang tersimpan
  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? defaultUsername;
  }

  // ============================================================
  // PASSWORD MANAGEMENT - Manajemen perubahan password
  // ============================================================

  /// Mengubah password pengguna
  /// Validasi password lama sebelum mengizinkan perubahan
  ///
  /// [oldPassword] - Password lama untuk verifikasi
  /// [newPassword] - Password baru yang akan disimpan
  /// [newUsername] - Username baru (opsional, null = tidak diubah)
  ///
  /// Mengembalikan Map dengan:
  /// - 'success': bool - apakah operasi berhasil
  /// - 'message': String - pesan hasil operasi
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    String? newUsername,
  }) async {
    // ---- Validasi Input ----

    // Cek field tidak kosong
    if (oldPassword.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Password lama tidak boleh kosong',
      };
    }

    if (newPassword.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Password baru tidak boleh kosong',
      };
    }

    // Validasi panjang password minimal 4 karakter
    if (newPassword.trim().length < 4) {
      return {
        'success': false,
        'message': 'Password baru minimal 4 karakter',
      };
    }

    final prefs = await SharedPreferences.getInstance();

    // Ambil password yang tersimpan untuk verifikasi
    final storedPassword =
        prefs.getString(_keyPassword) ?? defaultPassword;

    // Verifikasi password lama
    if (oldPassword.trim() != storedPassword) {
      return {
        'success': false,
        'message': 'Password lama tidak sesuai',
      };
    }

    // Simpan password baru ke SharedPreferences
    await prefs.setString(_keyPassword, newPassword.trim());

    // Update username jika diberikan
    if (newUsername != null && newUsername.trim().isNotEmpty) {
      await prefs.setString(_keyUsername, newUsername.trim());
    }

    return {
      'success': true,
      'message': 'Password berhasil diubah',
    };
  }

  /// Mereset semua data autentikasi ke default
  /// BERBAHAYA: Hanya untuk keperluan testing
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, defaultUsername);
    await prefs.setString(_keyPassword, defaultPassword);
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
