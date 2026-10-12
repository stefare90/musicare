import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

Future<List<Track>> fetchAllPages(
  Future<PaginatedResult<Track>> Function(int offset, int limit) loader,
) async {
  const limit = 20;
  final all = <Track>[];
  while (true) {
    final page = await loader(all.length, limit);
    all.addAll(page.items);
    if (all.length >= page.total || page.items.isEmpty) break;
  }
  return all;
}
