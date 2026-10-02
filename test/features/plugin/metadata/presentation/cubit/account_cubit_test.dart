import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/account_repository.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockAuthService extends Mock implements IAuth {}

class MockUserService extends Mock implements IUser {}

void main() {
  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockAuthService auth;
  late MockUserService user;
  late AccountCubit cubit;

  setUp(() {
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    auth = MockAuthService();
    user = MockUserService();
    cubit = AccountCubit(AccountRepository(engine));

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.auth).thenReturn(auth);
    when(() => metadata.user).thenReturn(user);
  });

  tearDown(() => cubit.close());

  test('initialize emits the authenticated identity', () async {
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'listener'});

    await cubit.initialize();

    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.userName, 'listener');
  });

  test('initialize stays signed out when not authenticated', () async {
    when(() => auth.isAuthenticated()).thenAnswer((_) async => false);

    await cubit.initialize();

    expect(cubit.state.isAuthenticated, isFalse);
    expect(cubit.state.userName, isNull);
  });

  test('signIn authenticates and reports success with the user name', () async {
    when(() => auth.authenticate()).thenAnswer((_) async {});
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'listener'});

    final result = await cubit.signIn();

    expect(result, AuthResult.authenticated);
    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.userName, 'listener');
  });

  test('signIn reports cancellation when the form is dismissed', () async {
    when(() => auth.authenticate()).thenAnswer((_) async {});
    when(() => auth.isAuthenticated()).thenAnswer((_) async => false);

    final result = await cubit.signIn();

    expect(result, AuthResult.cancelled);
    expect(cubit.state.isAuthenticated, isFalse);
  });

  test('signIn reports failure and keeps the signed-out state', () async {
    when(
      () => auth.authenticate(),
    ).thenThrow(const MetadataAuthRequiredException('bad token'));

    final result = await cubit.signIn();

    expect(result, AuthResult.failed);
    expect(cubit.state.isAuthenticated, isFalse);
  });

  test('signOut clears the identity', () async {
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'listener'});
    await cubit.initialize();

    when(() => auth.logout()).thenAnswer((_) async {});
    await cubit.signOut();

    expect(cubit.state.isAuthenticated, isFalse);
    expect(cubit.state.userName, isNull);
  });
}
