import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented after a full HTTP disk cache clear (see `api_full_refresh.dart`).
/// Providers that `ref.watch` this refetch from the server when the user pulls refresh.
final apiRemoteDataEpochProvider = StateProvider<int>((ref) => 0);
