import 'dart:math';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';

enum RepeatMode {
  off,
  all,
  one;

  RepeatMode next() {
    switch (this) {
      case RepeatMode.off:
        return RepeatMode.all;
      case RepeatMode.all:
        return RepeatMode.one;
      case RepeatMode.one:
        return RepeatMode.off;
    }
  }
}

/// Pure Dart queue state and manipulation engine.
class PlaybackQueue {
  final List<Track> _originalTracks = [];
  final List<Track> _effectiveTracks = [];
  int _currentIndex = 0;
  bool _isShuffled = false;
  RepeatMode _repeatMode = RepeatMode.off;

  PlaybackQueue();

  /// Unmodifiable view of currently active tracks (shuffled or sequential).
  List<Track> get tracks => List.unmodifiable(_effectiveTracks);

  /// Unmodifiable view of original tracks order.
  List<Track> get originalTracks => List.unmodifiable(_originalTracks);

  int get currentIndex => _currentIndex;
  int get length => _effectiveTracks.length;
  bool get isEmpty => _effectiveTracks.isEmpty;
  bool get isNotEmpty => _effectiveTracks.isNotEmpty;
  bool get isShuffled => _isShuffled;
  RepeatMode get repeatMode => _repeatMode;

  Track? get currentTrack {
    if (isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _effectiveTracks.length) {
      return null;
    }
    return _effectiveTracks[_currentIndex];
  }

  bool get hasNext {
    if (isEmpty) return false;
    if (_repeatMode == RepeatMode.all || _repeatMode == RepeatMode.one) {
      return true;
    }
    return _currentIndex + 1 < _effectiveTracks.length;
  }

  bool get hasPrevious {
    if (isEmpty) return false;
    if (_repeatMode == RepeatMode.all) return true;
    return _currentIndex > 0;
  }

  /// Sets a new queue and updates the pointer to [startIndex].
  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _originalTracks
      ..clear()
      ..addAll(tracks);

    _isShuffled = false;
    _effectiveTracks
      ..clear()
      ..addAll(tracks);

    _currentIndex = (startIndex >= 0 && startIndex < _effectiveTracks.length)
        ? startIndex
        : 0;
  }

  /// Advances to next track according to RepeatMode rules.
  /// Returns next track or null if queue has finished.
  Track? next() {
    if (isEmpty) return null;

    if (_repeatMode == RepeatMode.one) {
      return currentTrack;
    }

    if (_currentIndex + 1 < _effectiveTracks.length) {
      _currentIndex++;
      return currentTrack;
    }

    if (_repeatMode == RepeatMode.all) {
      _currentIndex = 0;
      return currentTrack;
    }

    return null;
  }

  /// Moves to previous track according to RepeatMode rules.
  Track? previous() {
    if (isEmpty) return null;

    if (_currentIndex > 0) {
      _currentIndex--;
      return currentTrack;
    }

    if (_repeatMode == RepeatMode.all && _effectiveTracks.isNotEmpty) {
      _currentIndex = _effectiveTracks.length - 1;
      return currentTrack;
    }

    return null;
  }

  /// Jumps directly to track at specified index.
  Track? jumpToIndex(int index) {
    if (index >= 0 && index < _effectiveTracks.length) {
      _currentIndex = index;
      return currentTrack;
    }
    return null;
  }

  /// Toggles shuffle mode.
  /// When enabling, current track remains at index 0 and rest are shuffled.
  /// When disabling, original order is restored while maintaining current track.
  void toggleShuffle({Random? random}) {
    if (isEmpty) return;

    final current = currentTrack;
    _isShuffled = !_isShuffled;

    if (_isShuffled) {
      final remaining = List<Track>.from(_originalTracks);
      if (current != null) {
        remaining.removeWhere((t) => t.id == current.id);
      }
      remaining.shuffle(random);

      _effectiveTracks
        ..clear()
        ..add(current!)
        ..addAll(remaining);
      _currentIndex = 0;
    } else {
      _effectiveTracks
        ..clear()
        ..addAll(_originalTracks);
      if (current != null) {
        final originalIdx = _effectiveTracks.indexWhere(
          (t) => t.id == current.id,
        );
        _currentIndex = originalIdx >= 0 ? originalIdx : 0;
      }
    }
  }

  /// Sets repeat mode.
  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }

  /// Cycles through repeat modes: off -> all -> one -> off.
  RepeatMode cycleRepeatMode() {
    _repeatMode = _repeatMode.next();
    return _repeatMode;
  }

  /// Appends a track to the end of the queue.
  void add(Track track) {
    _originalTracks.add(track);
    _effectiveTracks.add(track);
  }

  /// Inserts a track immediately after current track.
  void insertNext(Track track) {
    _originalTracks.add(track);
    if (isEmpty) {
      _effectiveTracks.add(track);
      _currentIndex = 0;
    } else {
      _effectiveTracks.insert(_currentIndex + 1, track);
    }
  }

  /// Removes a track at [index].
  void removeAt(int index) {
    if (index < 0 || index >= _effectiveTracks.length) return;

    final removedTrack = _effectiveTracks.removeAt(index);
    _originalTracks.removeWhere((t) => t.id == removedTrack.id);

    if (_effectiveTracks.isEmpty) {
      _currentIndex = 0;
      return;
    }

    if (index < _currentIndex) {
      _currentIndex--;
    } else if (_currentIndex >= _effectiveTracks.length) {
      _currentIndex = _effectiveTracks.length - 1;
    }
  }

  /// Reorders track position in the active queue.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _effectiveTracks.length ||
        newIndex < 0 ||
        newIndex >= _effectiveTracks.length ||
        oldIndex == newIndex) {
      return;
    }

    final item = _effectiveTracks.removeAt(oldIndex);
    _effectiveTracks.insert(newIndex, item);

    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
  }

  /// Clears the queue.
  void clear() {
    _originalTracks.clear();
    _effectiveTracks.clear();
    _currentIndex = 0;
    _isShuffled = false;
  }
}
