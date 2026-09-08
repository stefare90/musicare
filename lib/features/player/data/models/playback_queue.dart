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

  List<Track> get tracks => List.unmodifiable(_effectiveTracks);
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
    if (_repeatMode != RepeatMode.off) {
      return true;
    }
    return _currentIndex + 1 < _effectiveTracks.length;
  }

  bool get hasPrevious {
    if (isEmpty) return false;
    if (_repeatMode == RepeatMode.all) return true;
    return _currentIndex > 0;
  }

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

  Track? jumpToIndex(int index) {
    if (index >= 0 && index < _effectiveTracks.length) {
      _currentIndex = index;
      return currentTrack;
    }
    return null;
  }

  void toggleShuffle() {
    if (isEmpty) return;

    final current = currentTrack;
    _isShuffled = !_isShuffled;

    if (_isShuffled) {
      _currentIndex = 0;
      _effectiveTracks.clear();
      final remaining = List<Track>.from(_originalTracks);
      if (current != null) {
        _effectiveTracks.add(current);
        final idx = remaining.indexWhere((t) => t.id == current.id);
        if (idx >= 0) {
          remaining.removeAt(idx);
        }
      }
      remaining.shuffle();
      _effectiveTracks.addAll(remaining);
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

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }

  RepeatMode cycleRepeatMode() {
    _repeatMode = _repeatMode.next();
    return _repeatMode;
  }

  void add(Track track) {
    _originalTracks.add(track);
    _effectiveTracks.add(track);
  }

  void insertNext(Track track) {
    _originalTracks.add(track);
    if (isEmpty) {
      _effectiveTracks.add(track);
      _currentIndex = 0;
    } else {
      _effectiveTracks.insert(_currentIndex + 1, track);
    }
  }

  void removeAt(int index) {
    if (index < 0 || index >= _effectiveTracks.length) return;

    final removedTrack = _effectiveTracks.removeAt(index);

    if (!_isShuffled) {
      _originalTracks.removeAt(index);
    } else {
      final origIndex = _originalTracks.indexWhere(
        (t) => t.id == removedTrack.id,
      );
      if (origIndex >= 0) {
        _originalTracks.removeAt(origIndex);
      }
    }

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

  void clear() {
    _originalTracks.clear();
    _effectiveTracks.clear();
    _currentIndex = 0;
    _isShuffled = false;
  }
}
