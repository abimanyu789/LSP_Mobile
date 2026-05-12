import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'task_list_screen.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Halaman Beranda (Dashboard) - Pusat navigasi utama aplikasi
///
/// Fitur yang diimplementasikan:
/// - Ringkasan statistik tugas (total, selesai, belum selesai)
/// - Grafik bar chart statistik tugas harian (7 hari terakhir)
/// - Navigasi ke empat menu utama:
///   1. Tambah Tugas Penting
///   2. Tambah Tugas Biasa
///   3. Daftar Semua Tugas
///   4. Pengaturan
/// - Greeting berdasarkan waktu (pagi/siang/sore/malam)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State untuk HomeScreen
/// Mengelola:
/// - Data statistik tugas dari database
/// - State loading
/// - Refresh data saat kembali dari halaman lain
class _HomeScreenState extends State<HomeScreen> {

  // SERVICE INSTANCES

  /// Service database untuk mengambil data statistik
  final DatabaseService _dbService = DatabaseService();

  /// Service auth untuk fungsi logout
  final AuthService _authService = AuthService();

  // STATE VARIABLES

  /// Data statistik tugas (total, selesai, belum selesai, penting, biasa)
  Map<String, int> _taskCounts = {
    'total': 0,
    'completed': 0,
    'pending': 0,
    'penting': 0,
    'biasa': 0,
  };

  /// Data grafik harian untuk bar chart
  List<Map<String, dynamic>> _dailyStats = [];

  /// Status loading data
  bool _isLoading = true;

  /// Username pengguna yang sedang login (untuk greeting)
  String _username = 'Pengguna';

  // LIFECYCLE METHODS

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // DATA LOADING METHODS

  /// Memuat semua data yang diperlukan untuk dashboard
  /// Dipanggil saat initState dan setiap kali halaman di-refresh
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Muat semua data secara paralel menggunakan Future.wait
      // Lebih efisien daripada await satu per satu
      final results = await Future.wait([
        _dbService.getTaskCounts(), // Statistik jumlah tugas
        _dbService.getDailyStats(), // Data grafik harian
        _authService.getCurrentUsername(), // Username pengguna
      ]);

      if (!mounted) return;

      setState(() {
        _taskCounts = results[0] as Map<String, int>;
        _dailyStats = results[1] as List<Map<String, dynamic>>;
        _username = results[2] as String;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Melakukan logout dan kembali ke halaman login
  Future<void> _handleLogout() async {
    // Tampilkan dialog konfirmasi sebelum logout
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      // Kembali ke halaman login, hapus semua halaman sebelumnya
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Hapus semua route yang ada
      );
    }
  }

  // HELPER METHODS

  /// Mendapatkan pesan greeting berdasarkan jam saat ini
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // UI BUILD METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              // Pull-to-refresh untuk memperbarui data
              onRefresh: _loadDashboardData,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                // Tambahkan physics agar RefreshIndicator bisa bekerja
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Header dengan greeting dan statistik ----
                    _buildHeaderSection(),

                    // ---- Menu navigasi empat grid ----
                    _buildMenuSection(),

                    // ---- Grafik statistik harian ----
                    _buildChartSection(),

                    // ---- Spacer di bawah ----
                    const SizedBox(height: AppTheme.spacingXL),
                  ],
                ),
              ),
            ),
    );
  }

  /// Membangun AppBar dengan tombol logout
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Agenda Nusantara'),
      actions: [
        // Tombol refresh manual
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Perbarui Data',
          onPressed: _loadDashboardData,
        ),
        // Tombol logout
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Keluar',
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  /// Membangun bagian header berisi greeting dan summary card
  Widget _buildHeaderSection() {
    return Container(
      // Padding: 20px semua sisi
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        // Gradient biru untuk konsistensi dengan halaman login
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Greeting Text ----
          Text(
            '${_getGreeting()}, $_username! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppTheme.spacingXS),

          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // ---- Summary Cards Row ----
          Row(
            children: [
              // Card: Total Tugas
              Expanded(
                child: _buildSummaryCard(
                  label: 'Total',
                  count: _taskCounts['total'] ?? 0,
                  icon: Icons.list_alt,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),

              // Card: Selesai
              Expanded(
                child: _buildSummaryCard(
                  label: 'Selesai',
                  count: _taskCounts['completed'] ?? 0,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF81C784), // Hijau muda
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),

              // Card: Belum Selesai
              Expanded(
                child: _buildSummaryCard(
                  label: 'Pending',
                  count: _taskCounts['pending'] ?? 0,
                  icon: Icons.pending_outlined,
                  color: const Color(0xFFFFCC80), // Orange muda
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun satu summary card statistik
  /// [label] - Label yang ditampilkan
  /// [count] - Angka statistik
  /// [icon] - Icon Material Design
  /// [color] - Warna ikon dan angka
  Widget _buildSummaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingMD,
        horizontal: AppTheme.spacingSM,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15), // Semi-transparan putih
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun bagian menu utama dengan 4 kartu menu
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Menu Utama', style: AppTheme.subtitleStyle),
          const SizedBox(height: AppTheme.spacingMD),

          // Grid 2x2 untuk empat menu utama
          GridView.count(
            crossAxisCount: 2, // 2 kolom
            shrinkWrap: true, // Sesuaikan tinggi dengan konten
            physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll grid
            crossAxisSpacing: AppTheme.spacingMD, // Jarak horizontal: 16px
            mainAxisSpacing: AppTheme.spacingMD, // Jarak vertikal: 16px
            childAspectRatio: 1.2, // Rasio lebar:tinggi
            children: [
              // Menu 1: Tambah Tugas Penting
              _buildMenuCard(
                title: 'Tugas Penting',
                subtitle: '${_taskCounts['penting'] ?? 0} tugas',
                icon: Icons.priority_high,
                color: AppTheme.colorPenting,
                bgColor: AppTheme.colorPentingLight,
                onTap: () => _navigateToAddTask('penting'),
              ),

              // Menu 2: Tambah Tugas Biasa
              _buildMenuCard(
                title: 'Tugas Biasa',
                subtitle: '${_taskCounts['biasa'] ?? 0} tugas',
                icon: Icons.add_task,
                color: AppTheme.colorBiasa,
                bgColor: AppTheme.colorBiasaLight,
                onTap: () => _navigateToAddTask('biasa'),
              ),

              // Menu 3: Daftar Tugas
              _buildMenuCard(
                title: 'Daftar Tugas',
                subtitle: '${_taskCounts['total'] ?? 0} total',
                icon: Icons.format_list_bulleted,
                color: AppTheme.primaryColor,
                bgColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                onTap: _navigateToTaskList,
              ),

              // Menu 4: Pengaturan
              _buildMenuCard(
                title: 'Pengaturan',
                subtitle: 'Kelola akun',
                icon: Icons.settings_outlined,
                color: AppTheme.textSecondary,
                bgColor: AppTheme.textSecondary.withValues(alpha: 0.1),
                onTap: _navigateToSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun satu kartu menu navigasi
  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container ikon dengan warna background
            Container(
              width: 52, // Lebar: 52px
              height: 52, // Tinggi: 52px
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun bagian grafik bar chart statistik harian
  Widget _buildChartSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Container(
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
            // ---- Header Chart ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Aktivitas 7 Hari Terakhir',
                    style: AppTheme.subtitleStyle),
                // Legend
                Row(
                  children: [
                    _buildLegend('Dibuat', AppTheme.primaryColor),
                    const SizedBox(width: AppTheme.spacingSM),
                    _buildLegend('Selesai', AppTheme.successColor),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // ---- Bar Chart ----
            SizedBox(
              height: 180, // Tinggi chart: 180px
              child: _dailyStats.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada data tugas',
                        style: AppTheme.captionStyle,
                      ),
                    )
                  : _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun legenda untuk chart
  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.captionStyle),
      ],
    );
  }

  /// Membangun bar chart menggunakan fl_chart
  Widget _buildBarChart() {
    // Cari nilai maksimum untuk menentukan skala Y axis
    int maxValue = 1;
    for (final stat in _dailyStats) {
      final total = (stat['total'] as int?) ?? 0;
      if (total > maxValue) maxValue = total;
    }

    return BarChart(
      BarChartData(
        // ---- Konfigurasi alignment ----
        alignment: BarChartAlignment.spaceAround,

        // ---- Nilai maksimum Y axis (dengan sedikit padding atas) ----
        maxY: (maxValue + 1).toDouble(),

        // ---- Konfigurasi Bar Touch ----
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // Callback untuk konten tooltip
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),

        // ---- Konfigurasi Titles (label) ----
        titlesData: FlTitlesData(
          // Label kiri (Y axis) - tampilkan angka bulat
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28, // Lebar reserved untuk label: 28px
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value == value.roundToDouble()) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTheme.captionStyle,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Label bawah (X axis) - tampilkan tanggal singkat
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _dailyStats.length) {
                  return const SizedBox.shrink();
                }
                final dateStr = _dailyStats[index]['date'] as String? ?? '';
                if (dateStr.isEmpty) return const SizedBox.shrink();
                try {
                  final date = DateTime.parse(dateStr);
                  return Text(
                    DateFormat('d/M').format(date),
                    style: AppTheme.captionStyle,
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),

          // Sembunyikan label atas dan kanan
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        // ---- Garis grid ----
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false, // Hanya garis horizontal
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFE0E0E0),
            strokeWidth: 1,
          ),
        ),

        // ---- Border chart ----
        borderData: FlBorderData(show: false),

        // ---- Data bar groups ----
        barGroups: _dailyStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final total = (stat['total'] as int? ?? 0).toDouble();
          final completed = (stat['completed'] as int? ?? 0).toDouble();

          return BarChartGroupData(
            x: index,
            barRods: [
              // Bar untuk total tugas (biru)
              BarChartRodData(
                toY: total,
                color: AppTheme.primaryColor,
                width: 12, // Lebar bar: 12px
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              // Bar untuk tugas selesai (hijau)
              BarChartRodData(
                toY: completed,
                color: AppTheme.successColor,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // NAVIGATION METHODS - Metode navigasi ke halaman lain

  /// Navigasi ke halaman Tambah Tugas dengan jenis yang ditentukan
  Future<void> _navigateToAddTask(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(defaultType: type),
      ),
    );

    // Refresh data jika ada tugas yang ditambahkan (result == true)
    if (result == true) {
      _loadDashboardData();
    }
  }

  /// Navigasi ke halaman Daftar Tugas
  Future<void> _navigateToTaskList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskListScreen()),
    );
    // Refresh statistik setelah kembali dari daftar tugas
    _loadDashboardData();
  }

  /// Navigasi ke halaman Pengaturan
  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    // Refresh username yang mungkin berubah di pengaturan
    _loadDashboardData();
  }
}
