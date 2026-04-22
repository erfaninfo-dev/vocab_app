import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/admin_user_row.dart';
import '../../data/services/api_service.dart';

final adminUsersListProvider =
    FutureProvider.autoDispose<List<AdminUserRow>>((ref) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) {
    throw StateError('signed_out');
  }
  if (!session.user.isAdmin) {
    throw StateError('not_admin');
  }
  return ApiService(authToken: session.token).fetchAdminUsers();
});
