import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/admin_user_row.dart';
import '../../data/services/api_service.dart';
import '../../domain/api_remote_data_epoch.dart';

final adminUsersListProvider =
    FutureProvider.autoDispose<AdminUsersListResult>((ref) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) {
    throw StateError('signed_out');
  }
  if (!session.user.isAdmin) {
    throw StateError('not_admin');
  }
  return ApiService(authToken: session.token).fetchAdminUsers();
});
