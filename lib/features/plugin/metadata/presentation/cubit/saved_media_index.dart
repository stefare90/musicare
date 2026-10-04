import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

/// The global saved-media index as the loading and writing cubits see it: the
/// [changes] stream they reload from, plus [refresh] for a cubit whose write
/// changes the saved set.
///
/// It deliberately carries only the media type, not the entity: it is a
/// listing-level "the saved set of this type changed" bus, consumed by the
/// library tabs and *Liked Songs*.
///
/// Consumers depend on this port, not on the concrete cubit, exactly like
/// `AccountSession`: the data-loading cubits only need the stream and the
/// ability to re-read the set.
abstract interface class SavedMediaIndex {
  /// Emits a type only for a genuine change, never for the warm-up.
  Stream<MediaItemType> get changes;

  /// Re-reads the saved IDs of [type], announcing on [changes] only when
  /// [notify] is true and the returned set differs from the last read.
  ///
  /// A silent refresh ([notify] false) is used by pull-to-refresh, which
  /// reloads the listing explicitly and would otherwise trigger it twice.
  Future<void> refresh(MediaItemType type, {bool notify = true});
}
