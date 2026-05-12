import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

/// Halaman Login - Pintu masuk utama aplikasi Agenda Nusantara
///
/// Fitur yang diimplementasikan:
/// - Input username dan password dengan validasi
/// - Kredensial default: username='user', password='user'
/// - Dapat diubah melalui menu Pengaturan
/// - Error handling dengan pesan yang informatif
/// - Tampilan modern dengan gradient header
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State untuk LoginScreen
/// Mengelola:
/// - Controller untuk input field
/// - State loading saat proses autentikasi
/// - Visibilitas password (show/hide)
/// - Form key untuk validasi
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // CONTROLLERS - Pengontrol untuk input field

  /// Controller untuk field username
  final TextEditingController _usernameController = TextEditingController();

  /// Controller untuk field password
  final TextEditingController _passwordController = TextEditingController();

  /// Key untuk Form widget - digunakan untuk validasi semua field sekaligus
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // STATE VARIABLES - Variabel state lokal halaman login

  /// Service autentikasi untuk memvalidasi kredensial
  final AuthService _authService = AuthService();

  /// Apakah sedang dalam proses autentikasi (tampilkan loading indicator)
  bool _isLoading = false;

  /// Apakah password saat ini ditampilkan atau disembunyikan
  bool _isPasswordVisible = false;

  /// Pesan error yang ditampilkan saat login gagal
  String? _errorMessage;

  /// Controller untuk animasi fade-in saat halaman pertama dibuka
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // LIFECYCLE METHODS

  @override
  void initState() {
    super.initState();

    // Setup animasi fade-in untuk tampilan halaman
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Curve ease-in untuk animasi yang natural
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Mulai animasi saat halaman pertama dibuka
    _animationController.forward();
  }

  @override
  void dispose() {
    // PENTING: Selalu dispose controller untuk mencegah memory leak
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // BUSINESS LOGIC - Logika autentikasi

  /// Memproses login saat tombol "Masuk" ditekan
  /// Validasi form → Autentikasi → Navigasi ke Home atau tampilkan error
  Future<void> _handleLogin() async {
    // Reset pesan error sebelumnya
    setState(() => _errorMessage = null);

    // Validasi semua field dalam form
    // Form.validate() akan menjalankan validator pada setiap TextFormField
    if (!_formKey.currentState!.validate()) {
      return; // Hentikan jika ada field tidak valid
    }

    // Tampilkan loading indicator
    setState(() => _isLoading = true);

    try {
      // Panggil service autentikasi untuk memvalidasi kredensial
      final isSuccess = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      // Cek apakah widget masih mounted sebelum update state
      // (penting untuk async operation)
      if (!mounted) return;

      if (isSuccess) {
        // Login berhasil - navigasi ke halaman utama
        // pushReplacement: hapus halaman login dari navigation stack
        // sehingga tombol back tidak bisa kembali ke login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Login gagal - tampilkan pesan error
        setState(() {
          _errorMessage = 'Username atau password salah. Silakan coba lagi.';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle unexpected error (misal: storage tidak dapat diakses)
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  // UI BUILD METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Warna latar belakang sesuai tema
      backgroundColor: AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---- HEADER SECTION - Bagian atas dengan gradient biru ----
              _buildHeader(context),

              // ---- FORM SECTION - Formulir login ----
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun bagian header halaman login
  /// Menampilkan logo/icon aplikasi, nama app, dan tagline
  Widget _buildHeader(BuildContext context) {
    return Container(
      // Tinggi header: 35% dari tinggi layar agar proporsional di berbagai device
      height: MediaQuery.of(context).size.height * 0.35,

      // Lebar mengisi seluruh layar
      width: double.infinity,

      // Gradient biru sebagai latar belakang header
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryDark,
          ],
        ),
        // Hanya sudut bawah yang dibuat membulat (wave effect sederhana)
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        // Bayangan untuk efek depth
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ---- Ikon Aplikasi ----
          Container(
            width: 80, // Lebar container ikon: 80px
            height: 80, // Tinggi container ikon: 80px
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.task_alt, // Ikon checklist/task
              size: 48, // Ukuran ikon: 48px
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16), // Jarak antara ikon dan teks: 16px

          // ---- Nama Aplikasi ----
          const Text(
            'Agenda Nusantara',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5, // Sedikit spasi antar huruf untuk keterbacaan
            ),
          ),

          const SizedBox(height: 8), // Jarak: 8px

          // ---- Tagline ----
          Text(
            'Kelola Tugas Anda dengan Mudah',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun formulir login dengan input username, password, dan tombol masuk
  Widget _buildLoginForm() {
    return Padding(
      // Padding: 24px kiri-kanan, 32px atas-bawah
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLG,
        vertical: AppTheme.spacingXL,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Judul Form ----
            const Text(
              'Selamat Datang!',
              style: AppTheme.headlineStyle,
            ),

            const SizedBox(height: AppTheme.spacingXS), // Jarak: 4px

            const Text(
              'Silakan masuk untuk melanjutkan',
              style: AppTheme.captionStyle,
            ),

            const SizedBox(height: AppTheme.spacingXL), // Jarak: 32px

            // ---- Error Message Banner ----
            if (_errorMessage != null) _buildErrorBanner(),

            // ---- Username Field ----
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Masukkan username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              // Nonaktifkan autocorrect untuk field username
              autocorrect: false,
              textInputAction: TextInputAction.next, // Enter → pindah ke password
              validator: (value) {
                // Validasi: username tidak boleh kosong
                if (value == null || value.trim().isEmpty) {
                  return 'Username tidak boleh kosong';
                }
                return null; // null berarti valid
              },
            ),

            const SizedBox(height: AppTheme.spacingMD), // Jarak: 16px

            // ---- Password Field ----
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan password',
                prefixIcon: const Icon(Icons.lock_outline),
                // Tombol show/hide password
                suffixIcon: IconButton(
                  onPressed: () {
                    // Toggle visibilitas password
                    setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    );
                  },
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              // Sembunyikan teks jika _isPasswordVisible = false
              obscureText: !_isPasswordVisible,
              // Aktifkan enter untuk submit form
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: AppTheme.spacingXL), // Jarak: 32px

            // ---- Tombol Login ----
            SizedBox(
              width: double.infinity, // Tombol mengisi lebar penuh
              height: 52, // Tinggi tombol: 52px (ukuran yang mudah ditekan)
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                // Tampilkan loading spinner atau teks "Masuk"
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Masuk'),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLG), // Jarak: 24px

            // ---- Informasi Kredensial Default ----
            // _buildDefaultCredentialInfo(),
          ],
        ),
      ),
    );
  }

  /// Widget banner pesan error
  /// Ditampilkan saat login gagal di atas form
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget info kredensial default
  /// Membantu pengguna mengetahui kredensial awal aplikasi
  // Widget _buildDefaultCredentialInfo() {
  //   return Container(
  //     padding: const EdgeInsets.all(AppTheme.spacingMD),
  //     decoration: BoxDecoration(
  //       color: AppTheme.infoColor.withValues(alpha: 0.08),
  //       borderRadius: BorderRadius.circular(AppTheme.radiusSM),
  //       border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.2)),
  //     ),
  //     child: const Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(
  //               Icons.info_outline,
  //               color: AppTheme.infoColor,
  //               size: 16,
  //             ),
  //             SizedBox(width: AppTheme.spacingXS),
  //             Text(
  //               'Informasi Login Default',
  //               style: TextStyle(
  //                 color: AppTheme.infoColor,
  //                 fontWeight: FontWeight.w600,
  //                 fontSize: 13,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: AppTheme.spacingXS),
  //         Text(
  //           'Username: user\nPassword: user',
  //           style: TextStyle(
  //             color: AppTheme.textSecondary,
  //             fontSize: 12,
  //             height: 1.6, // Line height untuk keterbacaan
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
