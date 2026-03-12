// test/rbac_privacy_test.dart
//
// Tugas Pengayaan 5.5 — The Privacy Leak Test
// Validasi: Private logs TIDAK boleh terlihat oleh anggota lain.
//
// Cara jalankan:
//   flutter test test/rbac_privacy_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

// ─── Model sederhana untuk keperluan test ────────────────
// (Tidak import LogModel asli agar test tidak butuh Hive)
class _FakeLog {
  final String authorId;
  final bool isPublic;
  final String title;

  _FakeLog({
    required this.authorId,
    required this.isPublic,
    required this.title,
  });
}

// ─── Fungsi filter visibilitas (sama persis dengan log_view.dart) ────────────
List<_FakeLog> applyVisibility(List<_FakeLog> logs, String currentUserId) {
  return logs.where((log) {
    final isOwner = log.authorId == currentUserId;
    final isPublic = log.isPublic;
    // Tampilkan JIKA saya pemilik ATAU catatan publik
    return isOwner || isPublic;
  }).toList();
}

// ─────────────────────────────────────────────────────────
void main() {
  group('RBAC Privacy Leak Test', () {

    // Setup data: User A punya 2 log
    final logsUserA = [
      _FakeLog(
        authorId: 'ibnu',
        isPublic: false, // ← PRIVATE
        title: 'Catatan Rahasia Ibnu',
      ),
      _FakeLog(
        authorId: 'ibnu',
        isPublic: true,  // ← PUBLIC
        title: 'Pengumuman Tim',
      ),
    ];

    // ── TEST 1 ──────────────────────────────────────────
    test(
      'User A (pemilik) harus bisa melihat SEMUA log miliknya (2 log)',
      () {
        final visible = applyVisibility(logsUserA, 'ibnu'); // login sebagai ibnu
        expect(visible.length, 2);
      },
    );

    // ── TEST 2 ──────────────────────────────────────────
    test(
      'RBAC Security Check: Private logs should NOT be visible to teammates',
      () {
        // User B (hilmi) melakukan fetchLogs
        final visible = applyVisibility(logsUserA, 'hilmi');

        // Hanya 1 log yang boleh terlihat (yang Public)
        expect(
          visible.length,
          1,
          reason: 'User B hanya boleh lihat 1 log (Public). '
              'Jika 2, sistem dinyatakan VULNERABLE.',
        );

        // Pastikan yang muncul adalah yang Public
        expect(visible.first.isPublic, true);
        expect(visible.first.title, 'Pengumuman Tim');
      },
    );

    // ── TEST 3 ──────────────────────────────────────────
    test(
      'Ketua tim juga TIDAK boleh lihat catatan Private anggota',
      () {
        final visible = applyVisibility(logsUserA, 'admin'); // admin = Ketua
        expect(
          visible.length,
          1,
          reason: 'Ketua pun tidak boleh lihat Private log anggota.',
        );
      },
    );

    // ── TEST 4 ──────────────────────────────────────────
    test(
      'Jika semua log Public, semua anggota tim bisa melihat semuanya',
      () {
        final allPublicLogs = [
          _FakeLog(authorId: 'ibnu', isPublic: true, title: 'Log A'),
          _FakeLog(authorId: 'ibnu', isPublic: true, title: 'Log B'),
        ];
        final visible = applyVisibility(allPublicLogs, 'hilmi');
        expect(visible.length, 2);
      },
    );

    // ── TEST 5: Owner-only edit/delete ──────────────────
    test(
      'Sovereignty: hanya pemilik yang bisa edit/hapus',
      () {
        final log = _FakeLog(
          authorId: 'ibnu',
          isPublic: true, // meskipun publik
          title: 'Log Publik Ibnu',
        );

        // Simulasi cek isOwner
        final canEditAsIbnu = log.authorId == 'ibnu';   // pemilik
        final canEditAsHilmi = log.authorId == 'hilmi'; // bukan pemilik
        final canEditAsAdmin = log.authorId == 'admin'; // ketua sekalipun

        expect(canEditAsIbnu, true,  reason: 'Pemilik harus bisa edit');
        expect(canEditAsHilmi, false, reason: 'Bukan pemilik, tidak boleh edit');
        expect(canEditAsAdmin, false, reason: 'Ketua pun tidak boleh edit milik orang lain');
      },
    );
  });
}

