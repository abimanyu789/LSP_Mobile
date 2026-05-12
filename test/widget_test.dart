// Gunakan 'test' package murni karena test ini adalah unit test Dart
// bukan widget test Flutter (tidak butuh WidgetTester atau MaterialApp)
// flutter_test sudah meng-export semua dari package:test/test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_nusantara/models/task_model.dart';

/// ============================================================
/// UNIT TEST - Agenda Nusantara
/// ============================================================
///
/// Menguji fungsionalitas utama aplikasi:
/// 1. TaskModel - konversi data dan properti helper
/// 2. Validasi Input - logika validasi form
///
/// Cara menjalankan:
///   flutter test test/widget_test.dart
///   flutter test                        (semua test)
void main() {
  // Inisialisasi Flutter binding untuk unit test
  // Diperlukan meskipun tidak ada widget yang ditest
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // GROUP 1: TaskModel Tests
  // ============================================================
  group('TaskModel Tests', () {
    /// Test 1: Nilai default TaskModel harus sesuai spesifikasi
    test('TaskModel dibuat dengan nilai default yang benar', () {
      // Buat tugas baru tanpa menentukan type/isCompleted
      const task = TaskModel(
        title: 'Belajar Flutter',
        dueDate: '2026-06-01',
        createdAt: '2026-05-09T10:00:00',
      );

      // Verifikasi semua nilai default
      expect(task.type, equals('biasa'));       // Default: biasa
      expect(task.isCompleted, isFalse);        // Default: belum selesai
      expect(task.description, equals(''));     // Default: deskripsi kosong
      expect(task.id, isNull);                  // Default: belum ada ID (belum disimpan)
    });

    /// Test 2: Konversi TaskModel ke Map harus menghasilkan struktur database yang benar
    test('TaskModel.toMap() menghasilkan Map yang benar', () {
      const task = TaskModel(
        id: 1,
        title: 'Tugas Ujian',
        description: 'Persiapkan materi',
        type: 'penting',
        dueDate: '2026-06-15',
        isCompleted: true,
        createdAt: '2026-05-09T08:00:00',
      );

      // Konversi ke Map (format yang disimpan ke SQLite)
      final map = task.toMap();

      expect(map['id'], equals(1));
      expect(map['title'], equals('Tugas Ujian'));
      expect(map['type'], equals('penting'));
      // PENTING: boolean isCompleted disimpan sebagai integer 1/0 di SQLite
      expect(map['is_completed'], equals(1));
      expect(map['due_date'], equals('2026-06-15'));
    });

    /// Test 3: Parsing dari Map (hasil query SQLite) harus menghasilkan TaskModel yang benar
    test('TaskModel.fromMap() membuat TaskModel yang benar dari Map', () {
      // Simulasi data yang diterima dari query SQLite
      final map = {
        'id': 2,
        'title': 'Meeting Tim',
        'description': 'Diskusi proyek',
        'type': 'penting',
        'due_date': '2026-05-20',
        'is_completed': 0, // SQLite menyimpan 0 untuk false
        'created_at': '2026-05-09T09:00:00',
      };

      // Parse Map menjadi TaskModel
      final task = TaskModel.fromMap(map);

      expect(task.id, equals(2));
      expect(task.title, equals('Meeting Tim'));
      expect(task.type, equals('penting'));
      // Konversi integer 0 → false
      expect(task.isCompleted, isFalse);
      // Helper getter isPenting harus true untuk type 'penting'
      expect(task.isPenting, isTrue);
    });

    /// Test 4: copyWith harus membuat salinan dengan perubahan yang benar (immutable pattern)
    test('TaskModel.copyWith() membuat salinan dengan perubahan yang benar', () {
      const original = TaskModel(
        id: 3,
        title: 'Tugas Awal',
        dueDate: '2026-06-01',
        createdAt: '2026-05-01T00:00:00',
      );

      // Hanya ubah status isCompleted, properti lain harus tetap sama
      final updated = original.copyWith(isCompleted: true);

      // Properti yang berubah
      expect(updated.isCompleted, isTrue);

      // Properti yang tidak diubah harus tetap sama persis
      expect(updated.id, equals(original.id));
      expect(updated.title, equals(original.title));
      expect(updated.dueDate, equals(original.dueDate));
    });

    /// Test 5: Helper getter isPenting harus mengembalikan nilai yang tepat
    test('TaskModel.isPenting mengembalikan nilai yang tepat', () {
      const pentingTask = TaskModel(
        title: 'Penting',
        type: 'penting',
        dueDate: '2026-06-01',
        createdAt: '2026-05-01T00:00:00',
      );

      const biasaTask = TaskModel(
        title: 'Biasa',
        type: 'biasa',
        dueDate: '2026-06-01',
        createdAt: '2026-05-01T00:00:00',
      );

      expect(pentingTask.isPenting, isTrue);   // Tugas penting → true
      expect(biasaTask.isPenting, isFalse);    // Tugas biasa → false
    });

    /// Test 6: Helper getter typeLabel harus mengembalikan label yang sesuai bahasa Indonesia
    test('TaskModel.typeLabel mengembalikan label yang benar', () {
      const pentingTask = TaskModel(
        title: 'Test',
        type: 'penting',
        dueDate: '2026-06-01',
        createdAt: '2026-05-01T00:00:00',
      );

      const biasaTask = TaskModel(
        title: 'Test',
        type: 'biasa',
        dueDate: '2026-06-01',
        createdAt: '2026-05-01T00:00:00',
      );

      expect(pentingTask.typeLabel, equals('Penting'));  // 'penting' → 'Penting'
      expect(biasaTask.typeLabel, equals('Biasa'));       // 'biasa' → 'Biasa'
    });
  });

  // ============================================================
  // GROUP 2: Input Validation Tests
  // ============================================================
  group('Validasi Input Tests', () {
    /// Test 7: Judul tugas tidak boleh kosong atau hanya spasi
    test('Judul tugas tidak boleh kosong', () {
      const emptyTitle = '';
      const validTitle = 'Belajar Flutter';

      // Simulasi fungsi validasi yang digunakan di form
      bool validateTitle(String title) => title.trim().isNotEmpty;

      expect(validateTitle(emptyTitle), isFalse);   // String kosong → tidak valid
      expect(validateTitle(validTitle), isTrue);     // String valid → valid
      expect(validateTitle('   '), isFalse);         // Hanya spasi → tidak valid
    });

    /// Test 8: Password harus minimal 4 karakter
    test('Password minimal 4 karakter', () {
      bool validatePassword(String password) => password.trim().length >= 4;

      expect(validatePassword('abc'), isFalse);           // 3 karakter → gagal
      expect(validatePassword('abcd'), isTrue);           // 4 karakter → lulus
      expect(validatePassword('password123'), isTrue);    // > 4 karakter → lulus
    });

    /// Test 9: Konfirmasi password harus cocok dengan password baru
    test('Konfirmasi password harus cocok dengan password baru', () {
      bool validateConfirm(String password, String confirm) =>
          password.trim() == confirm.trim();

      expect(validateConfirm('pass123', 'pass123'), isTrue);   // Cocok → valid
      expect(validateConfirm('pass123', 'pass456'), isFalse);  // Tidak cocok → tidak valid
      expect(validateConfirm('pass123', ''), isFalse);         // Kosong → tidak valid
    });

    /// Test 10: Format tanggal ISO 8601 harus valid
    test('Format tanggal ISO 8601 valid', () {
      bool isValidDate(String dateStr) {
        if (dateStr.isEmpty) return false;
        try {
          DateTime.parse(dateStr);
          return true;
        } catch (_) {
          return false;
        }
      }

      expect(isValidDate('2026-06-01'), isTrue);       // Format valid
      expect(isValidDate('invalid-date'), isFalse);    // Format salah
      expect(isValidDate(''), isFalse);                // String kosong
    });
  });
}
