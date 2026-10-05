import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_audio_source_page.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_intro_page.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_metadata_page.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_dots_indicator.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _checkAndNavigateToHome(BuildContext context) {
    final metadataState = context.read<MetadataPluginCubit>().state;
    final audioSourceState = context.read<AudioSourcePluginCubit>().state;

    if (metadataState is MetadataPluginLoadedState &&
        audioSourceState is AudioSourcePluginLoadedState) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage > 0) {
          _goToPage(_currentPage - 1);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: MultiBlocListener(
            listeners: [
              BlocListener<MetadataPluginCubit, MetadataPluginState>(
                listener: (context, state) {
                  if (state is MetadataPluginLoadingState) {
                    Dialogs.showLoading(
                      context,
                      message: context.l10n.installingPlugin,
                    );
                  } else if (state is MetadataPluginLoadedState) {
                    Dialogs.hide(context);
                  } else if (state is MetadataPluginErrorState) {
                    Dialogs.hide(context);
                    sl<NoticeBus>().emit(Notice.error(state.error));
                  }
                },
              ),
              BlocListener<AudioSourcePluginCubit, AudioSourcePluginState>(
                listener: (context, state) {
                  if (state is AudioSourcePluginLoadingState) {
                    Dialogs.showLoading(
                      context,
                      message: context.l10n.installingPlugin,
                    );
                  } else if (state is AudioSourcePluginLoadedState) {
                    Dialogs.hide(context);
                  } else if (state is AudioSourcePluginErrorState) {
                    Dialogs.hide(context);
                    sl<NoticeBus>().emit(Notice.error(state.error));
                  }
                },
              ),
            ],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: _currentPage > 0
                              ? () => _goToPage(_currentPage - 1)
                              : null,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      WelcomeIntroPage(onSelectMetadataTap: () => _goToPage(1)),
                      WelcomeMetadataPage(onContinueTap: () => _goToPage(2)),
                      WelcomeAudioSourcePage(
                        onFinishTap: () => _checkAndNavigateToHome(context),
                      ),
                    ],
                  ),
                ),
                OnboardingDotsIndicator(currentPage: _currentPage),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
