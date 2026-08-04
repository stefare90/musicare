import 'package:dart_eval/dart_eval_bridge.dart';

Object unboxMediaItem(dynamic raw) {
  if (raw == null) {
    throw ArgumentError('raw cannot be null');
  }
  if (raw is $Value) return unboxMediaItem(raw.$value);
  if (raw is $Instance) return unboxMediaItem(raw.$reified);
  return raw as Object;
}
