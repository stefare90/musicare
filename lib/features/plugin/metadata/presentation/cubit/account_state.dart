/// The signed-in identity of the active metadata provider.
class AccountState {
  const AccountState({this.isAuthenticated = false, this.userName});

  final bool isAuthenticated;
  final String? userName;
}
