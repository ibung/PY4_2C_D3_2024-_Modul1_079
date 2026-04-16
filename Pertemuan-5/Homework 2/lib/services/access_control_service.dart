import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

  static const String actionCreate = 'create';
  static const String actionRead   = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  static final Map<String, List<String>> _rolePermissions = {
    'Ketua'   : [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota' : [actionCreate, actionRead],
    'Asisten' : [actionRead, actionUpdate],
  };

  // ─── FR-03: Role + Ownership check ──────────────────────────────────────────
  /// Mengembalikan true jika [role] boleh melakukan [action].
  ///
  /// Aturan khusus:
  /// - 'Ketua' → selalu boleh update/delete milik siapa pun.
  /// - 'Anggota' → hanya boleh update/delete data miliknya sendiri ([isOwner]).
  /// - 'Asisten' → boleh update, tapi tidak boleh delete data orang lain.
  static bool canPerform(
    String role,
    String action, {
    bool isOwner = false,
  }) {
    final permissions = _rolePermissions[role] ?? [];

    // Ketua punya akses penuh, tidak perlu cek ownership
    if (role == 'Ketua') return permissions.contains(action);

    // Anggota: update & delete HANYA kalau pemilik
    if (role == 'Anggota' &&
        (action == actionUpdate || action == actionDelete)) {
      return isOwner;
    }

    // Asisten: boleh update siapa pun, tapi delete hanya milik sendiri
    if (role == 'Asisten' && action == actionDelete) {
      return isOwner;
    }

    return permissions.contains(action);
  }

  // ─── FR-04: Team Isolation check ────────────────────────────────────────────
  /// Mengembalikan true jika [logTeamId] cocok dengan [userTeamId].
  /// Digunakan sebagai filter tambahan sebelum menampilkan log ke UI.
  static bool isTeamMember(String userTeamId, String logTeamId) {
    return userTeamId.isNotEmpty && userTeamId == logTeamId;
  }
}