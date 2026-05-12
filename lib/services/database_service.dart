import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

/// Service untuk mengelola semua operasi database SQLite
/// Mengimplementasikan pola Singleton untuk memastikan hanya ada satu instance database
/// yang berjalan selama siklus hidup aplikasi
class DatabaseService {
  // SINGLETON PATTERN - Pastikan hanya ada satu instance

  /// Instance tunggal dari DatabaseService (Singleton)
  static final DatabaseService _instance = DatabaseService._internal();

  /// Factory constructor yang selalu mengembalikan instance yang sama
  factory DatabaseService() => _instance;

  /// Private constructor untuk mencegah pembuatan instance dari luar
  DatabaseService._internal();

  // DATABASE INSTANCE

  /// Referensi ke database SQLite yang aktif
  /// Nullable karena belum tersedia sebelum inisialisasi
  Database? _database;

  /// Nama file database yang akan dibuat di storage perangkat
  static const String _databaseName = 'agenda_nusantara.db';

  /// Versi database (increment saat ada perubahan schema)
  static const int _databaseVersion = 1;

  // TABLE & COLUMN NAMES - Konstanta nama tabel dan kolom

  /// Nama tabel untuk menyimpan semua tugas
  static const String tableTask = 'tasks';

  /// Kolom-kolom pada tabel tasks
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colType = 'type';
  static const String colDueDate = 'due_date';
  static const String colIsCompleted = 'is_completed';
  static const String colCreatedAt = 'created_at';

  // DATABASE INITIALIZATION - Inisialisasi koneksi database

  /// Getter untuk mendapatkan database instance
  /// Jika belum ada, akan menginisialisasi database terlebih dahulu
  /// Lazy initialization: database hanya dibuat saat pertama diakses
  Future<Database> get database async {
    // Jika database sudah ada, langsung kembalikan
    if (_database != null) return _database!;

    // Inisialisasi database baru
    _database = await _initDatabase();
    return _database!;
  }

  /// Menginisialisasi database SQLite
  /// Menentukan lokasi file database di direktori dokumen aplikasi
  Future<Database> _initDatabase() async {
    // Mendapatkan path direktori database default
    final databasesPath = await getDatabasesPath();

    // Bergabungkan path direktori dengan nama file database
    // Hasilnya: /data/data/[package]/databases/agenda_nusantara.db
    final path = join(databasesPath, _databaseName);

    // Buka database, jalankan onCreate jika pertama kali
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      // onUpgrade dipanggil jika versi database berubah
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Callback yang dipanggil saat database pertama kali dibuat
  /// Membuat skema tabel sesuai kebutuhan aplikasi
  Future<void> _createDatabase(Database db, int version) async {
    // SQL untuk membuat tabel tasks dengan semua kolom yang diperlukan
    await db.execute('''
      CREATE TABLE $tableTask (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTitle TEXT NOT NULL,
        $colDescription TEXT DEFAULT '',
        $colType TEXT NOT NULL DEFAULT 'biasa',
        $colDueDate TEXT NOT NULL,
        $colIsCompleted INTEGER NOT NULL DEFAULT 0,
        $colCreatedAt TEXT NOT NULL
      )
    ''');
  }

  /// Callback untuk migrasi database ke versi baru
  /// Saat ini hanya placeholder untuk pengembangan selanjutnya
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Implementasi migrasi jika ada perubahan schema di masa depan
    // Contoh: ALTER TABLE tasks ADD COLUMN priority INTEGER DEFAULT 0;
  }

  // CRUD OPERATIONS - Create, Read, Update, Delete

  /// CREATE - Menyimpan tugas baru ke database
  /// Mengembalikan ID dari baris yang baru diinsert
  Future<int> insertTask(TaskModel task) async {
    final db = await database;

    // insert() mengembalikan rowId (id yang di-generate)
    return await db.insert(
      tableTask,
      task.toMap(),
      // Jika ada konflik (misal ID duplikat), ganti dengan data baru
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ ALL - Mengambil semua tugas dari database
  /// Diurutkan berdasarkan tanggal pembuatan (terbaru di atas)
  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;

    // Query semua baris dari tabel tasks
    final List<Map<String, dynamic>> maps = await db.query(
      tableTask,
      orderBy: '$colCreatedAt DESC', // Urutkan: terbaru di atas
    );

    // Konversi setiap Map menjadi TaskModel menggunakan factory constructor
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  /// READ BY TYPE - Mengambil tugas berdasarkan jenisnya ('penting'/'biasa')
  /// Berguna untuk menampilkan tugas berdasarkan kategori
  Future<List<TaskModel>> getTasksByType(String type) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableTask,
      where: '$colType = ?', // Gunakan placeholder '?' untuk keamanan (prevent SQL injection)
      whereArgs: [type], // Nilai yang menggantikan placeholder '?'
      orderBy: '$colCreatedAt DESC',
    );

    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  /// READ COUNT - Mendapatkan jumlah tugas berdasarkan status selesai
  /// Digunakan untuk menampilkan statistik di dashboard
  Future<Map<String, int>> getTaskCounts() async {
    final db = await database;

    // Hitung total tugas
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableTask',
    );

    // Hitung tugas yang sudah selesai
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableTask WHERE $colIsCompleted = 1',
    );

    // Hitung tugas penting
    final pentingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableTask WHERE $colType = "penting"',
    );

    // Hitung tugas biasa
    final biasaResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableTask WHERE $colType = "biasa"',
    );

    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    final completed = Sqflite.firstIntValue(completedResult) ?? 0;

    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
      'penting': Sqflite.firstIntValue(pentingResult) ?? 0,
      'biasa': Sqflite.firstIntValue(biasaResult) ?? 0,
    };
  }

  /// READ DAILY STATS - Mengambil statistik tugas per hari untuk grafik
  /// Mengembalikan data 7 hari terakhir untuk ditampilkan di chart
  Future<List<Map<String, dynamic>>> getDailyStats() async {
    final db = await database;

    // Query untuk mendapatkan jumlah tugas per tanggal (7 hari terakhir)
    final result = await db.rawQuery('''
      SELECT 
        DATE($colCreatedAt) as date,
        COUNT(*) as total,
        SUM($colIsCompleted) as completed
      FROM $tableTask
      WHERE DATE($colCreatedAt) >= DATE('now', '-6 days')
      GROUP BY DATE($colCreatedAt)
      ORDER BY date ASC
    ''');

    return result;
  }

  /// UPDATE - Memperbarui data tugas yang sudah ada di database
  /// Mengembalikan jumlah baris yang berhasil diperbarui
  Future<int> updateTask(TaskModel task) async {
    final db = await database;

    return await db.update(
      tableTask,
      task.toMap(),
      where: '$colId = ?', // Hanya update baris dengan ID yang sesuai
      whereArgs: [task.id],
    );
  }

  /// UPDATE COMPLETION STATUS - Toggle status selesai tugas
  /// Lebih efisien dari updateTask() karena hanya update satu kolom
  Future<int> toggleTaskCompletion(int id, bool isCompleted) async {
    final db = await database;

    return await db.update(
      tableTask,
      {colIsCompleted: isCompleted ? 1 : 0},
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// DELETE - Menghapus satu tugas berdasarkan ID
  /// Mengembalikan jumlah baris yang berhasil dihapus
  Future<int> deleteTask(int id) async {
    final db = await database;

    return await db.delete(
      tableTask,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// DELETE ALL - Menghapus semua tugas (digunakan untuk testing/reset)
  Future<int> deleteAllTasks() async {
    final db = await database;
    return await db.delete(tableTask);
  }

  /// Menutup koneksi database
  /// Dipanggil saat aplikasi ditutup untuk membebaskan resource
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
