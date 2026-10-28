import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_auth.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_entry.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_registry.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginLifecycle extends Mock implements PluginLifecycle {}

class MockPluginAuth extends Mock implements PluginAuth {}

void main() {
  late MockPluginLifecycle metadata;
  late MockPluginLifecycle audio;
  late MockPluginAuth metadataAuth;
  late StreamController<PluginLifecycleState> metadataChanges;
  late StreamController<PluginLifecycleState> audioChanges;
  late StreamController<PluginAuthState> authChanges;
  late NoticeBus notices;
  late PluginSessionCubit cubit;

  setUp(() {
    metadata = MockPluginLifecycle();
    audio = MockPluginLifecycle();
    metadataAuth = MockPluginAuth();
    metadataChanges = StreamController<PluginLifecycleState>.broadcast();
    audioChanges = StreamController<PluginLifecycleState>.broadcast();
    authChanges = StreamController<PluginAuthState>.broadcast();
    when(() => metadata.type).thenReturn(PluginType.metadata);
    when(() => audio.type).thenReturn(PluginType.audioSource);
    when(
      () => metadata.state,
    ).thenReturn(const PluginLifecycleState.notConfigured());
    when(
      () => audio.state,
    ).thenReturn(const PluginLifecycleState.notConfigured());
    when(() => metadata.changes).thenAnswer((_) => metadataChanges.stream);
    when(() => audio.changes).thenAnswer((_) => audioChanges.stream);
    when(
      () => metadataAuth.authState,
    ).thenReturn(const PluginAuthState.signedOut());
    when(() => metadataAuth.authChanges).thenAnswer((_) => authChanges.stream);
    when(() => metadataAuth.authenticate()).thenAnswer((_) async {});
    when(() => metadataAuth.logout()).thenAnswer((_) async {});

    notices = NoticeBus();
    cubit = PluginSessionCubit(
      PluginRegistry([
        PluginEntry(lifecycle: metadata, auth: metadataAuth),
        PluginEntry(lifecycle: audio),
      ]),
      notices,
    );
  });

  tearDown(() async {
    await cubit.close();
    await metadataChanges.close();
    await audioChanges.close();
    await authChanges.close();
  });

  test('exposes the initial lifecycle states by type', () {
    expect(
      cubit.stateOf(PluginType.metadata).status,
      PluginLifecycleStatus.notConfigured,
    );
    expect(
      cubit.stateOf(PluginType.audioSource).status,
      PluginLifecycleStatus.notConfigured,
    );
    expect(cubit.hasAuth(PluginType.metadata), isTrue);
    expect(cubit.hasAuth(PluginType.audioSource), isFalse);
  });

  test('updates the lifecycle state when a runtime emits', () async {
    final loaded = PluginLifecycleState.loaded(testPluginManifest());

    metadataChanges.add(loaded);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.stateOf(PluginType.metadata), loaded);
    expect(cubit.isLoaded(PluginType.metadata), isTrue);
    expect(cubit.manifestOf(PluginType.metadata)?.id, testPluginManifest().id);
  });

  test('aggregates auth state updates', () async {
    authChanges.add(const PluginAuthState.signedIn('listener'));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.authOf(PluginType.metadata).isAuthenticated, isTrue);
    expect(cubit.authOf(PluginType.metadata).accountId, 'listener');
    expect(
      cubit.authOf(PluginType.audioSource).status,
      PluginAuthStatus.unavailable,
    );
  });

  test('signIn and signOut delegate to the type auth', () async {
    await cubit.signIn(PluginType.metadata);
    await cubit.signOut(PluginType.metadata);
    await cubit.signIn(PluginType.audioSource);

    verify(() => metadataAuth.authenticate()).called(1);
    verify(() => metadataAuth.logout()).called(1);
  });

  test(
    'a failed authentication is announced and leaves the user signed out',
    () async {
      when(() => metadataAuth.authenticate()).thenThrow(Exception('bad token'));
      final seen = <Notice>[];
      final subscription = notices.notices.listen(seen.add);

      await cubit.signIn(PluginType.metadata);
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(1));
      expect(cubit.authOf(PluginType.metadata).isAuthenticated, isFalse);
      await subscription.cancel();
    },
  );
}
