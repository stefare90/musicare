part of 'user_cubit.dart';

/// Listing-level announcement: carries only the media type, not the entity.
abstract interface class UserSavedMediaIndex {
  /// Emits only genuine changes, never the warm-up.
  Stream<MediaItemType> get savedChanges;

  /// Re-reads the saved IDs, announcing only when [notify] is true and the
  /// set differs (a silent refresh is for pull-to-refresh, which reloads the
  /// listing explicitly).
  Future<void> refresh(MediaItemType type, {bool notify = true});
}
