import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/settings_button.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.libraryTab),
        actions: const [SettingsButton()],
      ),
      body: BlocBuilder<MetadataPluginCubit, MetadataPluginState>(
        builder: (context, state) {
          if (state is! MetadataPluginLoadedState) {
            return const SizedBox.shrink();
          }

          if (!state.isAuthenticated) {
            return Center(
              child: ErrorCard(error: const MetadataAuthRequiredException('')),
            );
          }

          // The saved-content tabs land with the user library task; until then
          // keep the same list skeleton used by the other content pages.
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [SkeletonTrackList(count: 8)],
          );
        },
      ),
    );
  }
}
