import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_audio_source_page.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_intro_page.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_metadata_page.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_dots_indicator.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';

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
    final plugins = context.read<PluginSessionCubit>();
    if (plugins.isLoaded(PluginType.metadata) &&
        plugins.isLoaded(PluginType.audioSource)) {
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
              BlocListener<PluginSessionCubit, PluginSessionState>(
                listenWhen: (previous, next) {
                  return PluginType.values.any(
                    (type) =>
                        previous.stateOf(type).status !=
                        next.stateOf(type).status,
                  );
                },
                listener: (context, state) {
                  final loading = state.states.values.any(
                    (plugin) => plugin.status == PluginLifecycleStatus.loading,
                  );
                  if (loading) {
                    Dialogs.showLoading(
                      context,
                      message: context.l10n.installingPlugin,
                    );
                  } else {
                    Dialogs.hide(context);
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
