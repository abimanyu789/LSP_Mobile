import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

/// Halaman Pengaturan - Manajemen akun dan informasi developer
///
/// Fitur yang diimplementasikan:
/// 1. Ganti Password - dengan validasi password lama
/// 2. Ganti Username - bersamaan dengan ganti password
/// 3. Profil Developer - Foto, Nama, dan NIM pengembang
///
/// Sesuai spesifikasi soal:
/// - Validasi password lama sebelum mengizinkan perubahan
/// - Identitas pengembang ditampilkan dengan foto
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State untuk SettingsScreen
class _SettingsScreenState extends State<SettingsScreen> {
  // ============================================================
  // CONTROLLERS - Controller untuk input field ganti password
  // ============================================================

  /// Controller untuk password lama
  final TextEditingController _oldPasswordController = TextEditingController();

  /// Controller untuk password baru
  final TextEditingController _newPasswordController = TextEditingController();

  /// Controller untuk konfirmasi password baru
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  /// Controller untuk username baru (opsional)
  final TextEditingController _newUsernameController = TextEditingController();

  /// Form key untuk validasi
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ============================================================
  // SERVICE & STATE
  // ============================================================

  final AuthService _authService = AuthService();

  /// Status loading saat simpan password
  bool _isLoading = false;

  /// Visibilitas masing-masing field password
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  /// Username saat ini
  String _currentUsername = '';

  // ============================================================
  // DEVELOPER INFO - Informasi pengembang yang ditampilkan
  // Ganti dengan data Anda sebenarnya!
  // ============================================================

  /// Nama lengkap pengembang
  static const String developerName = 'Ananda Abimanyu Saputra';

  /// Nomor Induk Mahasiswa (NIM)
  static const String developerNIM = '2241760093';

  /// Program studi/jurusan
  static const String developerProdi = 'Sistem Informasi Bisnis';

  /// Institusi/Sekolah
  static const String developerInstitusi = 'Politeknik Negeri Malang';

  // ============================================================
  // LIFECYCLE METHODS
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newUsernameController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA METHODS
  // ============================================================

  /// Memuat username saat ini dari SharedPreferences
  Future<void> _loadCurrentUsername() async {
    final username = await _authService.getCurrentUsername();
    if (!mounted) return;
    setState(() => _currentUsername = username);
  }

  /// Memproses perubahan password
  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Panggil service untuk ganti password
      final result = await _authService.changePassword(
        oldPassword: _oldPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        // Kirim username baru jika diisi
        newUsername: _newUsernameController.text.trim().isNotEmpty
            ? _newUsernameController.text.trim()
            : null,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Berhasil: bersihkan form dan tampilkan pesan sukses
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _newUsernameController.clear();

        // Reload username yang mungkin berubah
        _loadCurrentUsername();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Gagal: tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan. Silakan coba lagi.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // ============================================================
  // UI BUILD METHODS
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Profil Pengguna Saat Ini ----
            _buildCurrentUserCard(),

            const SizedBox(height: AppTheme.spacingMD),

            // ---- Form Ganti Password ----
            _buildChangePasswordSection(),

            const SizedBox(height: AppTheme.spacingMD),

            // ---- Profil Developer ----
            _buildDeveloperProfileSection(),

            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu profil pengguna saat ini
  Widget _buildCurrentUserCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        // Gradient biru untuk konsistensi tema
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          // Avatar pengguna (lingkaran dengan inisial)
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              _currentUsername.isNotEmpty
                  ? _currentUsername[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacingMD),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Login Sebagai',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _currentUsername,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun section form ganti password
  Widget _buildChangePasswordSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header Section ----
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              const Text('Ubah Password', style: AppTheme.subtitleStyle),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMD),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingMD),

          // ---- Form Fields ----
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Field: Username Baru (opsional)
                TextFormField(
                  controller: _newUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username Baru (Opsional)',
                    hintText: 'Kosongkan jika tidak diubah',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  autocorrect: false,
                  validator: (value) {
                    // Username baru bersifat opsional, tapi jika diisi harus valid
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        value.trim().length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // Field: Password Lama (wajib untuk verifikasi)
                TextFormField(
                  controller: _oldPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password Lama *',
                    hintText: 'Masukkan password saat ini',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _showOldPassword = !_showOldPassword),
                      icon: Icon(
                        _showOldPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  obscureText: !_showOldPassword,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password lama wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // Field: Password Baru
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password Baru *',
                    hintText: 'Minimal 4 karakter',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _showNewPassword = !_showNewPassword),
                      icon: Icon(
                        _showNewPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  obscureText: !_showNewPassword,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password baru wajib diisi';
                    }
                    if (value.trim().length < 4) {
                      return 'Password minimal 4 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // Field: Konfirmasi Password Baru
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru *',
                    hintText: 'Ulangi password baru',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword),
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  obscureText: !_showConfirmPassword,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    // Cek apakah konfirmasi password cocok dengan password baru
                    if (value.trim() != _newPasswordController.text.trim()) {
                      return 'Konfirmasi password tidak cocok';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // Tombol Simpan Password
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleChangePassword,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun section profil developer
  /// Menampilkan foto, nama, NIM, prodi, dan institusi pengembang
  Widget _buildDeveloperProfileSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header Section ----
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(
                  Icons.person_pin_outlined,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              const Text('Profil Pengembang', style: AppTheme.subtitleStyle),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMD),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingLG),

          // ---- Foto Developer ----
          Center(
            child: Column(
              children: [
                // Container foto dengan fallback jika foto tidak ada
                Container(
                  width: 100, // Lebar foto: 100px
                  height: 100, // Tinggi foto: 100px
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 3,
                    ),
                  ),
                  // Tampilkan foto dari assets jika ada
                  // Jika tidak ada, tampilkan ikon default
                  child: ClipOval(
                    child: _buildDeveloperPhoto(),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // ---- Nama Developer ----
                const Text(
                  developerName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingXS),

                // ---- NIM ----
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                  ),
                  child: const Text(
                    'NIM: $developerNIM',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // ---- Info Tambahan ----
          _buildInfoRow(Icons.school_outlined, 'Program Studi', developerProdi),
          const SizedBox(height: AppTheme.spacingSM),
          _buildInfoRow(
              Icons.business_outlined, 'Institusi', developerInstitusi),
          const SizedBox(height: AppTheme.spacingSM),
          _buildInfoRow(
              Icons.code_outlined, 'Aplikasi', 'Agenda Nusantara v1.0.0'),
          const SizedBox(height: AppTheme.spacingSM),
          _buildInfoRow(
              Icons.build_outlined, 'Teknologi', 'Flutter + SQLite'),
        ],
      ),
    );
  }

  /// Membangun tampilan foto developer
  /// Mencoba load dari assets, fallback ke ikon jika tidak ada
  Widget _buildDeveloperPhoto() {
    // Coba load foto dari assets
    // Jika gagal, tampilkan ikon pengganti
    return Image.asset(
      'assets/images/developer_photo.jpg',
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback: tampilkan ikon jika foto tidak tersedia
        return Container(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(
            Icons.person,
            size: 60,
            color: AppTheme.primaryColor,
          ),
        );
      },
    );
  }

  /// Membangun baris informasi dengan ikon, label, dan nilai
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.spacingSM),
        Text(
          '$label: ',
          style: AppTheme.captionStyle,
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
