import 'dart:async';

/// The account facts the data-loading cubits need: the current sign-in state and
/// a stream of its changes.
///
/// Not the whole `AccountState`: the user id is read from `AccountCubit`
/// through a `BlocBuilder`, not through this port. This port exists (instead
/// of a bare stream) because consumers also need the current value
/// synchronously — a broadcast stream does not replay it, and the app
/// initialises the account before those cubits are built.
abstract interface class AccountSession {
  bool get isAuthenticated;

  /// The provider id of the signed-in user, null when signed out.
  String? get userId;

  Stream<bool> get authenticationChanges;
}
