part of 'user_cubit.dart';

/// The signed-in user as the data-loading cubits see it: the current sign-in
/// state and a stream of its changes.
///
/// Not the whole `UserState`: the user id is read from `UserCubit` through a
/// `BlocBuilder`, not through this port. This port exists (instead of a bare
/// stream) because consumers also need the current value synchronously — a
/// broadcast stream does not replay it, and the app initialises the account
/// before those cubits are built.
abstract interface class UserSession {
  bool get isAuthenticated;

  /// The provider id of the signed-in user, null when signed out.
  String? get userId;

  Stream<bool> get authenticationChanges;
}
