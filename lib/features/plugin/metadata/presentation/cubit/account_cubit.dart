import 'dart:async';

import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/account_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_session.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_state.dart';

/// Outcome of an interactive sign-in attempt.
///
/// [cancelled] and [failed] are deliberately distinct: cancelling the provider
/// form is a normal user choice that must stay silent, while a failure (wrong
/// token, offline) deserves feedback.
enum AuthResult { authenticated, cancelled, failed }

/// Single source of truth for the account: the signed-in identity of the
/// active metadata plugin.
///
/// It observes [AccountRepository] (the data layer); every other cubit observes
/// only the sign-in boolean, through the small [AccountSession] port.
class AccountCubit extends SafeCubit<AccountState> implements AccountSession {
  AccountCubit(this._auth) : super(const AccountState());

  final AccountRepository _auth;

  @override
  bool get isAuthenticated => state.isAuthenticated;

  @override
  String? get userId => state.userId;

  /// Emits the sign-in state whenever it changes; a repeated value is dropped.
  ///
  /// A broadcast stream does not replay the current value: consumers read
  /// [isAuthenticated] for the initial state and subscribe for the changes.
  @override
  Stream<bool> get authenticationChanges =>
      stream.map((state) => state.isAuthenticated).distinct();

  /// Resolves the sign-in flag locally, then emits at once with the identity
  /// last known; the provider identity is refreshed in the background.
  ///
  /// Reading the identity needs a provider round-trip that can be slow or fail
  /// (offline boot). Emitting the cached value first keeps the app usable and
  /// avoids blocking `initialize()` (and therefore `runApp`) on the network.
  Future<void> initialize() async {
    if (!_auth.hasMetadata) return;
    var isAuthenticated = false;
    try {
      isAuthenticated = await _auth.isAuthenticated();
    } catch (_) {
      // Without the local flag we cannot claim a session; stay signed out.
    }
    if (isClosed) return;
    emit(
      AccountState(
        isAuthenticated: isAuthenticated,
        userId: isAuthenticated ? _auth.cachedUserId : null,
      ),
    );

    if (!isAuthenticated) return;
    unawaited(_refreshIdentity());
  }

  /// Resolves the identity from the provider and updates the state if it changed.
  Future<void> _refreshIdentity() async {
    try {
      final userId = await _auth.resolveUserId();
      if (isClosed || userId == null || userId == state.userId) return;
      emit(AccountState(isAuthenticated: state.isAuthenticated, userId: userId));
    } catch (_) {
      // The cached identity (if any) stays authoritative until the next attempt.
    }
  }

  Future<AuthResult> signIn() async {
    try {
      await _auth.authenticate();
      final isAuthenticated = await _auth.isAuthenticated();
      String? userId;
      if (isAuthenticated) {
        String? resolved;
        try {
          resolved = await _auth.resolveUserId();
        } catch (_) {
          resolved = null;
        }
        userId = resolved ?? _auth.cachedUserId;
      }
      if (isClosed) return AuthResult.cancelled;
      emit(AccountState(isAuthenticated: isAuthenticated, userId: userId));
      return isAuthenticated ? AuthResult.authenticated : AuthResult.cancelled;
    } catch (_) {
      return AuthResult.failed;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.logout();
    } catch (_) {
      // Keep the signed-out state even if the provider logout fails.
    }
    emit(const AccountState());
  }
}
