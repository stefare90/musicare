import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/management/data/services/plugin_manager.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class PluginManagerCubit extends SafeCubit<PluginManagerState> {
  final PluginManager _manager;
  final NoticeBus _notices;

  PluginManagerCubit(this._manager, this._notices)
    : super(
        PluginManagerState({
          for (final type in PluginType.values) type: const PluginSlotState(),
        }),
      );

  Future<void> refresh({
    bool force = false,
    bool fetchCatalog = true,
  }) async {
    for (final type in PluginType.values) {
      try {
        final snapshot = await _manager.snapshot(
          type,
          fetchCatalog: fetchCatalog,
        );
        _setSlot(
          type,
          state.slot(type).copyWith(
            installed: snapshot.installed,
            remote: snapshot.remote,
            updateAvailable: snapshot.updateAvailable,
            incompatible: snapshot.incompatible,
            error: null,
          ),
        );
      } catch (e) {
        _setSlot(type, state.slot(type).copyWith(error: e));
      }
    }
  }

  Future<void> update(PluginType type) => _applyFromRemote(type);

  Future<void> reinstall(PluginType type) async {
    var target = state.slot(type).remote;
    if (target == null) {
      _setSlot(
        type,
        state.slot(type).copyWith(phase: PluginSlotPhase.busy),
      );
      try {
        final snapshot = await _manager.snapshot(
          type,
          fetchCatalog: true,
        );
        _setSlot(
          type,
          state.slot(type).copyWith(
            installed: snapshot.installed,
            remote: snapshot.remote,
            updateAvailable: snapshot.updateAvailable,
            incompatible: snapshot.incompatible,
            phase: PluginSlotPhase.idle,
          ),
        );
        target = snapshot.remote ?? snapshot.installed;
      } catch (e) {
        _fail(type, e);
        return;
      }
    }
    if (target == null) {
      _fail(type, PluginDownloadException());
      return;
    }
    await _apply(type, target);
  }

  Future<void> change(PluginType type, PluginManifest target) =>
      _apply(type, target);

  Future<List<PluginManifest>> alternatives(PluginType type) =>
      _manager.alternatives(type);

  Future<void> _applyFromRemote(PluginType type) async {
    final remote = state.slot(type).remote;
    if (remote == null) {
      _fail(type, PluginDownloadException());
      return;
    }
    await _apply(type, remote);
  }

  Future<void> _apply(PluginType type, PluginManifest target) async {
    _setSlot(type, state.slot(type).copyWith(phase: PluginSlotPhase.busy));
    try {
      final manifest = await _manager.apply(type, target);
      _setSlot(
        type,
        PluginSlotState(
          installed: manifest,
          remote: target,
          phase: PluginSlotPhase.idle,
        ),
      );
    } catch (e) {
      _fail(type, e);
    }
  }

  void _fail(PluginType type, Object error) {
    _setSlot(
      type,
      state.slot(type).copyWith(phase: PluginSlotPhase.idle, error: error),
    );
    _notices.emit(Notice.error(error));
  }

  void _setSlot(PluginType type, PluginSlotState slot) {
    emit(PluginManagerState({...state.slots, type: slot}));
  }
}
