import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class MockPluginManagerCubit extends Mock
    implements PluginManagerCubit {}

PluginSlotState testPluginSlot({
  PluginManifest? installed,
  PluginManifest? remote,
  bool updateAvailable = false,
  bool incompatible = false,
  PluginSlotPhase phase = PluginSlotPhase.idle,
  Object? error,
}) {
  return PluginSlotState(
    installed: installed,
    remote: remote,
    updateAvailable: updateAvailable,
    incompatible: incompatible,
    phase: phase,
    error: error,
  );
}

PluginManagerState testManagerState({
  PluginManifest? metadata,
  PluginManifest? audioSource,
  PluginSlotState? metadataSlot,
  PluginSlotState? audioSourceSlot,
}) {
  return PluginManagerState({
    PluginType.metadata:
        metadataSlot ?? testPluginSlot(installed: metadata),
    PluginType.audioSource:
        audioSourceSlot ?? testPluginSlot(installed: audioSource),
  });
}

PluginManagerCubit buildMockPluginManagerCubit({
  PluginManagerState? state,
}) {
  final cubit = MockPluginManagerCubit();
  when(() => cubit.state).thenReturn(
    state ??
        testManagerState(
          metadata: null,
          audioSource: null,
        ),
  );
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(
    () => cubit.refresh(
      force: any(named: 'force'),
      fetchCatalog: any(named: 'fetchCatalog'),
    ),
  ).thenAnswer((_) async {});
  return cubit;
}
