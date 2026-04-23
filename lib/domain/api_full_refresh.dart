import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_providers.dart';
import 'api_remote_data_epoch.dart';

/// Clears all persisted GET response cache and bumps [apiRemoteDataEpochProvider] so
/// every API-backed provider that watches the epoch reloads from the network.
Future<void> refreshAllRemoteApiData(WidgetRef ref) async {
  await ref.read(apiServiceProvider).bustAllHttpGetDiskCache();
  ref.read(apiRemoteDataEpochProvider.notifier).state++;
}
