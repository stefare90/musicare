import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/account_repository.dart';
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
/// this one through `StateStreamable<AccountState>`.
class AccountCubit extends SafeCubit<AccountState> {
  AccountCubit(this._auth) : super(const AccountState());

  final AccountRepository _auth;

  Future<void> initialize() async {
    if (!_auth.hasMetadata) return;
    final isAuthenticated = await _auth.isAuthenticated();
    final userName = isAuthenticated ? await _auth.userName() : null;
    emit(AccountState(isAuthenticated: isAuthenticated, userName: userName));
  }

  Future<AuthResult> signIn() async {
    try {
      await _auth.authenticate();
      final isAuthenticated = await _auth.isAuthenticated();
      final userName = isAuthenticated ? await _auth.userName() : null;
      emit(AccountState(isAuthenticated: isAuthenticated, userName: userName));
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
