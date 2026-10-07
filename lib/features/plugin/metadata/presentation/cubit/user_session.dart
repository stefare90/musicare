part of 'user_cubit.dart';

/// The signed-in user as the data-loading cubits see it: a port (not a bare
/// stream) because consumers also need the current value synchronously.
abstract interface class UserSession {
  bool get isAuthenticated;

  String? get userId;

  Stream<bool> get authenticationChanges;
}
