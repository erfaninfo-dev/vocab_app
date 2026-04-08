import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped after a successful photo upload so [NetworkImage] URLs refresh.
final profilePhotoCacheNonceProvider = StateProvider<int>((ref) => 0);
