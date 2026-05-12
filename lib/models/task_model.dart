/// Model data untuk merepresentasikan sebuah Tugas (Task) dalam aplikasi
/// Kelas ini digunakan untuk memetakan data antara objek Dart dan tabel SQLite
class TaskModel {
  // ============================================================
  // PROPERTIES - Properti yang merepresentasikan kolom database
  // ============================================================

  /// ID unik tugas (auto-increment dari SQLite, null jika belum disimpan)
  final int? id;

  /// Judul/nama tugas yang wajib diisi
  final String title;

  /// Deskripsi detail tugas (opsional)
  final String description;

  /// Jenis tugas: 'penting' (merah) atau 'biasa' (hijau)
  final String type;

  /// Tanggal deadline tugas dalam format ISO 8601 (yyyy-MM-dd)
  final String dueDate;

  /// Status penyelesaian: true = selesai, false = belum selesai
  final bool isCompleted;

  /// Timestamp pembuatan tugas (untuk pengurutan dan statistik)
  final String createdAt;

  // ============================================================
  // CONSTRUCTOR - Konstruktor utama dengan named parameters
  // ============================================================

  /// Membuat instance TaskModel baru
  /// [id] - ID database (opsional, null untuk tugas baru)
  /// [title] - Judul tugas (wajib)
  /// [description] - Deskripsi tugas (default: string kosong)
  /// [type] - Jenis tugas 'penting'/'biasa' (default: 'biasa')
  /// [dueDate] - Tanggal jatuh tempo (wajib)
  /// [isCompleted] - Status selesai (default: false)
  /// [createdAt] - Waktu pembuatan (auto-generate jika tidak diisi)
  const TaskModel({
    this.id,
    required this.title,
    this.description = '',
    this.type = 'biasa',
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  // ============================================================
  // FACTORY METHODS - Metode untuk konversi data
  // ============================================================

  /// Membuat TaskModel dari Map (hasil query SQLite)
  /// SQLite menyimpan boolean sebagai integer (0/1)
  /// Konversi: isCompleted == 1 berarti true (selesai)
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'biasa',
      dueDate: map['due_date'] as String,
      // SQLite menyimpan 1 untuk true dan 0 untuk false
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  /// Mengkonversi TaskModel menjadi Map untuk disimpan ke SQLite
  /// Map key harus sesuai dengan nama kolom di database
  Map<String, dynamic> toMap() {
    return {
      // Jangan include 'id' saat insert (auto-increment)
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'type': type,
      'due_date': dueDate,
      // Konversi boolean ke integer untuk SQLite
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
    };
  }

  // ============================================================
  // COPY WITH - Untuk immutable state management
  // ============================================================

  /// Membuat salinan TaskModel dengan beberapa properti yang diubah
  /// Digunakan untuk memperbarui state tanpa mutasi langsung
  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? type,
    String? dueDate,
    bool? isCompleted,
    String? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ============================================================
  // HELPER GETTERS - Properti turunan untuk memudahkan akses
  // ============================================================

  /// Mengembalikan true jika tugas bertipe 'penting'
  bool get isPenting => type == 'penting';

  /// Mengembalikan label yang dapat ditampilkan di UI
  String get typeLabel => type == 'penting' ? 'Penting' : 'Biasa';

  @override
  String toString() {
    return 'TaskModel{id: $id, title: $title, type: $type, isCompleted: $isCompleted, dueDate: $dueDate}';
  }
}
