import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

/// Halaman Tambah/Edit Tugas
///
/// Mendukung dua mode:
/// 1. Mode Tambah - Menambahkan tugas baru (task == null)
/// 2. Mode Edit - Mengedit tugas yang sudah ada (task != null)
///
/// Fitur:
/// - Input judul tugas (wajib)
/// - Input deskripsi (opsional)
/// - Pilihan jenis tugas (Penting/Biasa) dengan tombol toggle
/// - Date picker untuk memilih tanggal deadline
/// - Validasi input sebelum menyimpan
class AddTaskScreen extends StatefulWidget {
  /// Jenis tugas default ('penting'/'biasa')
  /// Ditentukan dari menu yang ditekan di beranda
  final String defaultType;

  /// Data tugas yang akan diedit (null jika mode tambah)
  final TaskModel? task;

  const AddTaskScreen({
    super.key,
    this.defaultType = 'biasa',
    this.task,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

/// State untuk AddTaskScreen
class _AddTaskScreenState extends State<AddTaskScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  /// Controller untuk input judul tugas
  final TextEditingController _titleController = TextEditingController();

  /// Controller untuk input deskripsi tugas
  final TextEditingController _descController = TextEditingController();

  /// Form key untuk validasi semua field sekaligus
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ============================================================
  // SERVICE
  // ============================================================

  /// Service database untuk operasi CRUD
  final DatabaseService _dbService = DatabaseService();

  // ============================================================
  // STATE VARIABLES
  // ============================================================

  /// Jenis tugas yang dipilih ('penting' atau 'biasa')
  late String _selectedType;

  /// Tanggal deadline yang dipilih
  DateTime? _selectedDate;

  /// Status loading saat menyimpan ke database
  bool _isLoading = false;

  // ============================================================
  // LIFECYCLE METHODS
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Set jenis tugas default dari parameter
    _selectedType = widget.defaultType;

    // Jika mode edit, isi form dengan data tugas yang ada
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _selectedType = widget.task!.type;
      _selectedDate = DateTime.tryParse(widget.task!.dueDate);
    }
  }

  @override
  void dispose() {
    // Dispose semua controller untuk mencegah memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUSINESS LOGIC
  // ============================================================

  /// Membuka date picker untuk memilih tanggal deadline
  Future<void> _selectDate() async {
    final now = DateTime.now();

    // Tampilkan material date picker
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      // Tanggal minimal: hari ini (tidak bisa pilih tanggal masa lalu)
      firstDate: DateTime(now.year - 1),
      // Tanggal maksimal: 2 tahun ke depan
      lastDate: DateTime(now.year + 2),
      // Konfigurasi tampilan date picker
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Menyimpan tugas ke database
  /// Mode tambah: insert tugas baru
  /// Mode edit: update tugas yang ada
  Future<void> _saveTask() async {
    // Validasi form terlebih dahulu
    if (!_formKey.currentState!.validate()) return;

    // Validasi tanggal wajib dipilih
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih tanggal deadline'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.task == null) {
        // ---- MODE TAMBAH: Buat tugas baru ----
        final newTask = TaskModel(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          type: _selectedType,
          dueDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
          isCompleted: false,
          createdAt: DateTime.now().toIso8601String(),
        );

        await _dbService.insertTask(newTask);
      } else {
        // ---- MODE EDIT: Update tugas yang ada ----
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          type: _selectedType,
          dueDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        );

        await _dbService.updateTask(updatedTask);
      }

      if (!mounted) return;

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.task == null
                ? 'Tugas berhasil ditambahkan!'
                : 'Tugas berhasil diperbarui!',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Kembali ke halaman sebelumnya dan kirim result true
      // (menandakan ada perubahan data)
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Tampilkan pesan error jika gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan tugas: ${e.toString()}'),
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
    // Tentukan judul halaman berdasarkan mode (tambah/edit) dan jenis tugas
    final isEditMode = widget.task != null;
    final typeLabel = _selectedType == 'penting' ? 'Penting' : 'Biasa';
    final pageTitle =
        isEditMode ? 'Edit Tugas' : 'Tambah Tugas $typeLabel';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(pageTitle),
        // Ikon kembali otomatis dari Navigator.push
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Indikator Jenis Tugas ----
              _buildTypeSelector(),

              const SizedBox(height: AppTheme.spacingMD),

              // ---- Field Judul Tugas ----
              _buildTitleField(),

              const SizedBox(height: AppTheme.spacingMD),

              // ---- Field Deskripsi ----
              _buildDescriptionField(),

              const SizedBox(height: AppTheme.spacingMD),

              // ---- Pilih Tanggal ----
              _buildDatePicker(),

              const SizedBox(height: AppTheme.spacingXL),

              // ---- Tombol Simpan ----
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun selector jenis tugas (Penting/Biasa)
  /// Menggunakan ToggleButtons untuk pilihan eksklusif
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Tugas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),

        // Row dengan dua tombol pilihan jenis tugas
        Row(
          children: [
            // Tombol Penting
            Expanded(
              child: _buildTypeButton(
                label: 'Tugas Penting',
                icon: Icons.priority_high,
                type: 'penting',
                activeColor: AppTheme.colorPenting,
                activeBgColor: AppTheme.colorPentingLight,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSM),

            // Tombol Biasa
            Expanded(
              child: _buildTypeButton(
                label: 'Tugas Biasa',
                icon: Icons.task_outlined,
                type: 'biasa',
                activeColor: AppTheme.colorBiasa,
                activeBgColor: AppTheme.colorBiasaLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Membangun satu tombol pilihan jenis tugas
  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required String type,
    required Color activeColor,
    required Color activeBgColor,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Animasi transisi: 200ms
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMD,
          horizontal: AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : AppTheme.textSecondary, size: 20),
            const SizedBox(width: AppTheme.spacingXS),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun field input judul tugas
  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Judul Tugas *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Masukkan judul tugas...',
            prefixIcon: Icon(Icons.title),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLength: 100, // Batas maksimal 100 karakter
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Judul tugas tidak boleh kosong';
            }
            if (value.trim().length < 3) {
              return 'Judul tugas minimal 3 karakter';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Membangun field input deskripsi tugas
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi (Opsional)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        TextFormField(
          controller: _descController,
          decoration: const InputDecoration(
            hintText: 'Tambahkan keterangan tugas...',
            prefixIcon: Icon(Icons.notes),
            // Sejajarkan ikon ke atas untuk multiline
            alignLabelWithHint: true,
          ),
          maxLines: 3, // Tampilkan 3 baris
          maxLength: 500, // Batas maksimal 500 karakter
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  /// Membangun date picker untuk memilih tanggal deadline
  Widget _buildDatePicker() {
    // Format tanggal untuk ditampilkan di UI
    final dateText = _selectedDate != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate!)
        : 'Pilih tanggal deadline';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Deadline *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),

        // Tombol date picker yang terlihat seperti input field
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingMD,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(
                color: _selectedDate != null
                    ? AppTheme.primaryColor
                    : const Color(0xFFE0E0E0),
                width: _selectedDate != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _selectedDate != null
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Text(
                  dateText,
                  style: TextStyle(
                    color: _selectedDate != null
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Membangun tombol simpan
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveTask,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save),
        label: Text(widget.task == null ? 'Simpan Tugas' : 'Perbarui Tugas'),
      ),
    );
  }
}
