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

  /// Emits the sign-in state whenever it changes; a repeated value is dropped.
  ///
  /// A broadcast stream does not replay the current value: consumers read
  /// [isAuthenticated] for the initial state and subscribe for the changes.
  @override
  Stream<bool> get authenticationChanges =>
      stream.map((state) => state.isAuthenticated).distinct();

  Future<void> initialize() async {
    if (!_auth.hasMetadata) return;
    final isAuthenticated = await _auth.isAuthenticated();
    final userId = isAuthenticated ? await _auth.userId() : null;
    emit(AccountState(isAuthenticated: isAuthenticated, userId: userId));
  }

  Future<AuthResult> signIn() async {
    try {
      await _auth.authenticate();
      final isAuthenticated = await _auth.isAuthenticated();
      final userId = isAuthenticated ? await _auth.userId() : null;
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
