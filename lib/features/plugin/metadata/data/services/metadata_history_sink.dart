import 'package:flutter/foundation.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/listening/data/services/listen_sink.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';

class MetadataHistorySink implements ListenSink {
  MetadataHistorySink(this._engine, this._user);

  final MetadataPluginEngine _engine;
  final UserSession _user;
  String? _unsupportedPluginId;

  @override
  Future<void> submit(ListenEvent event) async {
    if (!_user.isAuthenticated) return;

    final pluginId = _engine.metadataManifest?.id;
    if (pluginId == null || pluginId == _unsupportedPluginId) return;

    try {
      await _engine.metadata.listen.record(event);
    } on MetadataUnsupportedException catch (error) {
      _unsupportedPluginId = pluginId;
      debugPrint('listening: no history from $pluginId ($error)');
    } catch (error) {
      debugPrint('listening: delivery failed ($error)');
    }
  }
}
