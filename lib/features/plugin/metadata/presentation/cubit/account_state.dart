/// The signed-in identity of the active metadata provider.
class AccountState {
  const AccountState({this.isAuthenticated = false, this.userId});

  final bool isAuthenticated;
  final String? userId;
}
