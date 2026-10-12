import 'package:flutter/foundation.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

typedef PendingLoader = Future<PaginatedResult<Track>> Function(int offset);

@immutable
class PendingSource {
  final PendingLoader loader;
  final int nextOffset;
  final int total;

  const PendingSource({
    required this.loader,
    required this.nextOffset,
    required this.total,
  });

  bool get isComplete => nextOffset >= total;

  int get remaining {
    final rest = total - nextOffset;
    return rest < 0 ? 0 : rest;
  }
}
