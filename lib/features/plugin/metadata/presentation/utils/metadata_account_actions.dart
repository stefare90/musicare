import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';

abstract class MetadataAccountActions {
  /// A real failure shows the error snackbar; a cancelled form stays silent.
  static Future<bool> signIn(BuildContext context) async {
    final result = await context.read<UserCubit>().signIn();
    if (result == AuthResult.failed && context.mounted) {
      sl<NoticeBus>().emit(Notice.message(context.l10n.authSignInFailed));
    }
    return result == AuthResult.authenticated;
  }

  static Future<void> signOut(BuildContext context) =>
      context.read<UserCubit>().signOut();
}
