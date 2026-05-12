import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import 'add_task_screen.dart';

/// Halaman Daftar Tugas - Menampilkan semua tugas dalam ListView
///
/// Fitur yang diimplementasikan:
/// - ListView scrollable menampilkan semua tugas
/// - Filter berdasarkan jenis tugas (Semua/Penting/Biasa)
/// - Filter berdasarkan status (Semua/Selesai/Belum)
/// - Indikator warna: merah=Penting, hijau=Biasa (sesuai spesifikasi)
/// - Checkbox/tap untuk toggle status selesai
/// - Swipe-to-delete untuk menghapus tugas
/// - Tap pada tugas untuk masuk mode edit
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

/// State untuk TaskListScreen
class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // SERVICE
  // ============================================================

  /// Service database untuk operasi CRUD
  final DatabaseService _dbService = DatabaseService();

  // ============================================================
  // STATE VARIABLES
  // ============================================================

  /// Daftar semua tugas dari database
  List<TaskModel> _allTasks = [];

  /// Daftar tugas yang sudah difilter (ditampilkan di UI)
  List<TaskModel> _filteredTasks = [];

  /// Status loading data
  bool _isLoading = true;

  /// Tab controller untuk filter jenis tugas (Semua/Penting/Biasa)
  late TabController _tabController;

  /// Filter status saat ini ('all'/'completed'/'pending')
  String _statusFilter = 'all';

  // ============================================================
  // LIFECYCLE METHODS
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Inisialisasi tab controller dengan 3 tab
    _tabController = TabController(length: 3, vsync: this);

    // Listener untuk update filter saat tab berubah
    _tabController.addListener(_applyFilters);

    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA METHODS
  // ============================================================

  /// Memuat semua tugas dari database
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final tasks = await _dbService.getAllTasks();
      if (!mounted) return;
      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Mengaplikasikan filter jenis dan status pada daftar tugas
  void _applyFilters() {
    List<TaskModel> filtered = List.from(_allTasks);

    // ---- Filter berdasarkan Tab (jenis tugas) ----
    switch (_tabController.index) {
      case 1: // Tab "Penting"
        filtered = filtered.where((t) => t.type == 'penting').toList();
        break;
      case 2: // Tab "Biasa"
        filtered = filtered.where((t) => t.type == 'biasa').toList();
        break;
      default: // Tab "Semua"
        break;
    }

    // ---- Filter berdasarkan Status ----
    switch (_statusFilter) {
      case 'completed':
        filtered = filtered.where((t) => t.isCompleted).toList();
        break;
      case 'pending':
        filtered = filtered.where((t) => !t.isCompleted).toList();
        break;
      default: // 'all'
        break;
    }

    setState(() => _filteredTasks = filtered);
  }

  /// Toggle status selesai sebuah tugas
  /// Dipanggil saat checkbox atau item di-tap
  Future<void> _toggleTaskCompletion(TaskModel task) async {
    try {
      await _dbService.toggleTaskCompletion(task.id!, !task.isCompleted);

      // Update state lokal tanpa perlu reload dari database (lebih responsif)
      final index = _allTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        setState(() {
          _allTasks[index] = task.copyWith(isCompleted: !task.isCompleted);
        });
        _applyFilters();
      }

      if (!mounted) return;

      // Tampilkan snackbar konfirmasi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            task.isCompleted
                ? 'Tugas ditandai belum selesai'
                : 'Tugas ditandai selesai! ✓',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: task.isCompleted
              ? AppTheme.warningColor
              : AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status tugas'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }


  /// Navigasi ke halaman edit tugas
  Future<void> _editTask(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(task: task),
      ),
    );

    if (result == true) {
      _loadTasks(); // Reload data jika ada perubahan
    }
  }

  // ============================================================
  // UI BUILD METHODS
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ---- Filter Status ----
          _buildStatusFilter(),

          // ---- List Tugas ----
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : _buildTaskList(),
          ),
        ],
      ),
      // FAB untuk tambah tugas baru
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTaskScreen(),
            ),
          );
          if (result == true) _loadTasks();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tugas'),
      ),
    );
  }

  /// Membangun AppBar dengan TabBar untuk filter jenis tugas
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Daftar Tugas'),
      bottom: TabBar(
        controller: _tabController,
        // Warna indikator tab yang aktif
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          // Tab Semua - tampilkan total count
          Tab(text: 'Semua (${_allTasks.length})'),
          // Tab Penting - tampilkan count penting
          Tab(
            text:
                'Penting (${_allTasks.where((t) => t.type == 'penting').length})',
          ),
          // Tab Biasa - tampilkan count biasa
          Tab(
            text:
                'Biasa (${_allTasks.where((t) => t.type == 'biasa').length})',
          ),
        ],
      ),
    );
  }

  /// Membangun filter status (Semua/Selesai/Belum)
  Widget _buildStatusFilter() {
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      child: Row(
        children: [
          const Text(
            'Status:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),

          // Chip filter: Semua
          _buildFilterChip('Semua', 'all'),
          const SizedBox(width: AppTheme.spacingXS),

          // Chip filter: Selesai
          _buildFilterChip('Selesai', 'completed'),
          const SizedBox(width: AppTheme.spacingXS),

          // Chip filter: Belum
          _buildFilterChip('Belum', 'pending'),
        ],
      ),
    );
  }

  /// Membangun chip filter status
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _statusFilter = value);
        _applyFilters();
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  /// Membangun daftar tugas menggunakan ListView
  Widget _buildTaskList() {
    return RefreshIndicator(
      onRefresh: _loadTasks,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppTheme.spacingSM,
          bottom: 80, // Padding bawah untuk FAB
        ),
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  /// Membangun satu kartu tugas dengan swipe-to-delete
  Widget _buildTaskCard(TaskModel task) {
    // Tentukan warna berdasarkan jenis tugas
    // PENTING: Merah, BIASA: Hijau (sesuai spesifikasi soal)
    final taskColor = AppTheme.getTaskColor(task.type);
    final taskLightColor = AppTheme.getTaskLightColor(task.type);

    return Dismissible(
      key: Key('task_${task.id}'),
      // Arah swipe: hanya ke kiri untuk hapus
      direction: DismissDirection.endToStart,

      // Background saat swipe (tampil warna merah dengan ikon delete)
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingLG),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),

      // Callback saat swipe selesai
      confirmDismiss: (_) async {
        // Gunakan dialog konfirmasi
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Tugas'),
            content: Text('Hapus "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },

      onDismissed: (_) async {
        setState(() {
          _allTasks.removeWhere((t) => t.id == task.id);
          _filteredTasks.removeWhere((t) => t.id == task.id);
        });
        await _dbService.deleteTask(task.id!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tugas dihapus')),
        );
      },

      // Konten kartu tugas
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingXS,
        ),
        child: InkWell(
          onTap: () => _editTask(task), // Tap untuk edit
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Indikator Warna Jenis Tugas (kiri) ----
                Container(
                  width: 4, // Lebar strip warna: 4px
                  height: 60, // Tinggi: 60px
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppTheme.colorCompleted : taskColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD),

                // ---- Checkbox Toggle Status ----
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => _toggleTaskCompletion(task),
                    activeColor: AppTheme.successColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spacingSM),

                // ---- Konten Tugas ----
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul tugas dengan strikethrough jika selesai
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          // Strikethrough untuk tugas yang selesai
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),

                      // Deskripsi (jika ada)
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description,
                          style: AppTheme.captionStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacingXS),

                      // Row: Badge jenis + Tanggal deadline
                      Row(
                        children: [
                          // Badge jenis tugas
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: task.isCompleted
                                  ? Colors.grey.shade100
                                  : taskLightColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: task.isCompleted
                                    ? AppTheme.textSecondary
                                    : taskColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(width: AppTheme.spacingXS),

                          // Tanggal deadline
                          const Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDate(task.dueDate),
                            style: AppTheme.captionStyle.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---- Tombol Edit (kanan) ----
                IconButton(
                  onPressed: () => _editTask(task),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  tooltip: 'Edit Tugas',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun tampilan kosong saat tidak ada tugas
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          const Text(
            'Tidak ada tugas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          const Text(
            'Tap tombol + untuk menambah tugas baru',
            style: AppTheme.captionStyle,
          ),
        ],
      ),
    );
  }

  /// Format tanggal dari string ISO ke format yang lebih readable
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
