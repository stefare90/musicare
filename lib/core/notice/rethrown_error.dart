/// An error that only wraps another one:
/// the presentation resolves the cause, not the wrapper.
abstract interface class RethrownError {
  Object get rethrown;
}
