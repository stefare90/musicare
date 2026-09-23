import 'package:flutter/foundation.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/player/data/models/playback_repeat_mode.dart';

@immutable
class PlaybackQueue {
  final List<Track> tracks;
  final List<Track> originalTracks;
  final int currentIndex;
  final bool isShuffled;
  final PlaybackRepeatMode repeatMode;

  const PlaybackQueue({
    this.tracks = const [],
    this.originalTracks = const [],
    this.currentIndex = 0,
    this.isShuffled = false,
    this.repeatMode = PlaybackRepeatMode.off,
  });

  int get length => tracks.length;
  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;

  Track? get currentTrack {
    if (isEmpty || currentIndex < 0 || currentIndex >= tracks.length) {
      return null;
    }
    return tracks[currentIndex];
  }

  bool get hasNext {
    if (isEmpty) return false;
    if (repeatMode == PlaybackRepeatMode.all ||
        repeatMode == PlaybackRepeatMode.one) {
      return true;
    }
    return currentIndex + 1 < tracks.length;
  }

  bool get hasPrevious {
    if (isEmpty) return false;
    if (repeatMode == PlaybackRepeatMode.all) return true;
    return currentIndex > 0;
  }

  PlaybackQueue setQueue(List<Track> newTracks, {int startIndex = 0}) {
    final validIndex = (startIndex >= 0 && startIndex < newTracks.length)
        ? startIndex
        : 0;
    return PlaybackQueue(
      tracks: List.unmodifiable(newTracks),
      originalTracks: List.unmodifiable(newTracks),
      currentIndex: validIndex,
      isShuffled: false,
      repeatMode: repeatMode,
    );
  }

  PlaybackQueue? next() {
    if (isEmpty) return null;

    if (repeatMode == PlaybackRepeatMode.one) {
      return this;
    }

    if (currentIndex + 1 < tracks.length) {
      return copyWith(currentIndex: currentIndex + 1);
    }

    if (repeatMode == PlaybackRepeatMode.all) {
      return copyWith(currentIndex: 0);
    }

    return null;
  }

  PlaybackQueue? previous() {
    if (isEmpty) return null;

    if (currentIndex > 0) {
      return copyWith(currentIndex: currentIndex - 1);
    }

    if (repeatMode == PlaybackRepeatMode.all && tracks.isNotEmpty) {
      return copyWith(currentIndex: tracks.length - 1);
    }

    return null;
  }

  PlaybackQueue? jumpToIndex(int index) {
    if (index >= 0 && index < tracks.length) {
      return copyWith(currentIndex: index);
    }
    return null;
  }

  PlaybackQueue toggleShuffle() {
    if (isEmpty) return this;

    final current = currentTrack;
    final newShuffled = !isShuffled;

    if (newShuffled) {
      final remaining = List<Track>.from(originalTracks);
      if (current != null) {
        final idx = remaining.indexWhere((t) => t.id == current.id);
        if (idx >= 0) {
          remaining.removeAt(idx);
        }
      }
      remaining.shuffle();

      final newTracks = <Track>[];
      if (current != null) {
        newTracks.add(current);
      }
      newTracks.addAll(remaining);

      return PlaybackQueue(
        tracks: List.unmodifiable(newTracks),
        originalTracks: originalTracks,
        currentIndex: 0,
        isShuffled: true,
        repeatMode: repeatMode,
      );
    } else {
      final restoredTracks = List<Track>.from(originalTracks);
      int restoredIndex = 0;
      if (current != null) {
        final originalIdx = restoredTracks.indexWhere(
          (t) => t.id == current.id,
        );
        restoredIndex = originalIdx >= 0 ? originalIdx : 0;
      }

      return PlaybackQueue(
        tracks: List.unmodifiable(restoredTracks),
        originalTracks: originalTracks,
        currentIndex: restoredIndex,
        isShuffled: false,
        repeatMode: repeatMode,
      );
    }
  }

  PlaybackQueue cycleRepeatMode() {
    return copyWith(repeatMode: repeatMode.next());
  }

  PlaybackQueue setRepeatMode(PlaybackRepeatMode mode) {
    return copyWith(repeatMode: mode);
  }

  PlaybackQueue add(Track track) {
    final newOriginal = List<Track>.from(originalTracks)..add(track);
    final newTracks = List<Track>.from(tracks)..add(track);
    return PlaybackQueue(
      tracks: List.unmodifiable(newTracks),
      originalTracks: List.unmodifiable(newOriginal),
      currentIndex: currentIndex,
      isShuffled: isShuffled,
      repeatMode: repeatMode,
    );
  }

  PlaybackQueue insertNext(Track track) {
    final newOriginal = List<Track>.from(originalTracks)..add(track);
    final newTracks = List<Track>.from(tracks);
    if (isEmpty) {
      newTracks.add(track);
    } else {
      newTracks.insert(currentIndex + 1, track);
    }
    return PlaybackQueue(
      tracks: List.unmodifiable(newTracks),
      originalTracks: List.unmodifiable(newOriginal),
      currentIndex: currentIndex,
      isShuffled: isShuffled,
      repeatMode: repeatMode,
    );
  }

  PlaybackQueue removeAt(int index) {
    if (index < 0 || index >= tracks.length) return this;

    final newTracks = List<Track>.from(tracks);
    final removedTrack = newTracks.removeAt(index);

    final newOriginal = List<Track>.from(originalTracks);
    if (!isShuffled) {
      newOriginal.removeAt(index);
    } else {
      final origIndex = newOriginal.indexWhere((t) => t.id == removedTrack.id);
      if (origIndex >= 0) {
        newOriginal.removeAt(origIndex);
      }
    }

    int newCurrentIndex = currentIndex;
    if (newTracks.isEmpty) {
      newCurrentIndex = 0;
    } else if (index < currentIndex) {
      newCurrentIndex--;
    } else if (newCurrentIndex >= newTracks.length) {
      newCurrentIndex = newTracks.length - 1;
    }

    return PlaybackQueue(
      tracks: List.unmodifiable(newTracks),
      originalTracks: List.unmodifiable(newOriginal),
      currentIndex: newCurrentIndex,
      isShuffled: isShuffled,
      repeatMode: repeatMode,
    );
  }

  PlaybackQueue reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= tracks.length ||
        newIndex < 0 ||
        newIndex >= tracks.length ||
        oldIndex == newIndex) {
      return this;
    }

    final newTracks = List<Track>.from(tracks);
    final item = newTracks.removeAt(oldIndex);
    newTracks.insert(newIndex, item);

    int newCurrentIndex = currentIndex;
    if (oldIndex == currentIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
      newCurrentIndex--;
    } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
      newCurrentIndex++;
    }

    return PlaybackQueue(
      tracks: List.unmodifiable(newTracks),
      originalTracks: originalTracks,
      currentIndex: newCurrentIndex,
      isShuffled: isShuffled,
      repeatMode: repeatMode,
    );
  }

  PlaybackQueue clear() {
    return const PlaybackQueue();
  }

  PlaybackQueue copyWith({
    List<Track>? tracks,
    List<Track>? originalTracks,
    int? currentIndex,
    bool? isShuffled,
    PlaybackRepeatMode? repeatMode,
  }) {
    return PlaybackQueue(
      tracks: tracks ?? this.tracks,
      originalTracks: originalTracks ?? this.originalTracks,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackQueue &&
          runtimeType == other.runtimeType &&
          currentIndex == other.currentIndex &&
          isShuffled == other.isShuffled &&
          repeatMode == other.repeatMode &&
          listEquals(tracks, other.tracks) &&
          listEquals(originalTracks, other.originalTracks);

  @override
  int get hashCode => Object.hash(
    currentIndex,
    isShuffled,
    repeatMode,
    Object.hashAll(tracks),
    Object.hashAll(originalTracks),
  );
}
