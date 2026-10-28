import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

abstract class PluginAccountActions {
  /// Returns whether the plugin ended up authenticated. Cancelling the form is
  /// silent; failures are announced by [PluginSessionCubit].
  static Future<bool> signIn(BuildContext context, PluginType type) async {
    final plugins = context.read<PluginSessionCubit>();
    await plugins.signIn(type);
    return plugins.authOf(type).isAuthenticated;
  }

  static Future<void> signOut(BuildContext context, PluginType type) =>
      context.read<PluginSessionCubit>().signOut(type);
}
