import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

abstract interface class ListenSink {
  Future<void> submit(ListenEvent event);
}
