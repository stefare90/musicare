import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/pages/full_player_page.dart';
import 'package:music_are/features/player/presentation/widgets/mini_player.dart';

class ShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellPage({super.key, required this.navigationShell});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelController;
  double _dragStartProgress = 0.0;

  static const double _miniPlayerHeight = 64.0;
  static const double _navBarHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _expand() {
    // Unfocus: the search field keeps focus under the player, and a route
    // opened from it would restore that focus on pop, reopening the keyboard.
    FocusManager.instance.primaryFocus?.unfocus();
    _panelController.animateTo(
      1.0,
      curve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 260),
    );
  }

  void _collapse() {
    _panelController.animateTo(
      0.0,
      curve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 260),
    );
  }

  void _handleDragStart(DragStartDetails details) {
    FocusManager.instance.primaryFocus?.unfocus();
    _panelController.stop();
    _dragStartProgress = _panelController.value;
  }

  void _handleDragUpdate(DragUpdateDetails details, double totalDistance) {
    if (totalDistance <= 0) return;
    _panelController.value -= details.primaryDelta! / totalDistance;
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity < -150) {
      _expand();
      return;
    }
    if (velocity > 150) {
      _collapse();
      return;
    }
    if (_dragStartProgress <= 0.3) {
      if (_panelController.value > 0.25) {
        _expand();
      } else {
        _collapse();
      }
    } else if (_dragStartProgress >= 0.7) {
      if (_panelController.value < 0.75) {
        _collapse();
      } else {
        _expand();
      }
    } else {
      if (_panelController.value > 0.5) {
        _expand();
      } else {
        _collapse();
      }
    }
  }

  void _handleDragCancel() {
    if (_dragStartProgress <= 0.3) {
      if (_panelController.value > 0.25) {
        _expand();
      } else {
        _collapse();
      }
    } else {
      if (_panelController.value < 0.75) {
        _collapse();
      } else {
        _expand();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTrack = context.select<PlayerCubit, bool>((c) => c.state.hasTrack);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final effectiveNavBarHeight = _navBarHeight + bottomInset;

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (_panelController.value > 0.0) {
          _collapse();
          return true;
        }
        return false;
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final dragDistance =
                screenHeight - effectiveNavBarHeight - _miniPlayerHeight;
            final contentBottomPadding = hasTrack
                ? (_miniPlayerHeight + effectiveNavBarHeight)
                : effectiveNavBarHeight;

            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: contentBottomPadding),
                    child: widget.navigationShell,
                  ),
                ),

                AnimatedBuilder(
                  animation: _panelController,
                  builder: (context, _) {
                    final progress = hasTrack ? _panelController.value : 0.0;
                    final navBarBottom = -(effectiveNavBarHeight * progress);
                    final playerBottom =
                        effectiveNavBarHeight * (1.0 - progress);
                    final playerHeight = hasTrack
                        ? (_miniPlayerHeight +
                              (screenHeight - _miniPlayerHeight) * progress)
                        : 0.0;

                    return Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: navBarBottom,
                          height: effectiveNavBarHeight,
                          child: NavigationBar(
                            selectedIndex: widget.navigationShell.currentIndex,
                            onDestinationSelected: (index) {
                              widget.navigationShell.goBranch(
                                index,
                                initialLocation:
                                    index ==
                                    widget.navigationShell.currentIndex,
                              );
                            },
                            destinations: [
                              NavigationDestination(
                                icon: const Icon(Icons.home_outlined),
                                selectedIcon: const Icon(Icons.home),
                                label: context.l10n.homeTab,
                              ),
                              NavigationDestination(
                                icon: const Icon(Icons.search_outlined),
                                selectedIcon: const Icon(Icons.search),
                                label: context.l10n.searchTab,
                              ),
                              NavigationDestination(
                                icon: const Icon(Icons.library_music_outlined),
                                selectedIcon: const Icon(Icons.library_music),
                                label: context.l10n.libraryTab,
                              ),
                            ],
                          ),
                        ),

                        if (hasTrack)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: playerBottom,
                            height: playerHeight,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragStart: _handleDragStart,
                              onVerticalDragUpdate: (details) =>
                                  _handleDragUpdate(details, dragDistance),
                              onVerticalDragEnd: _handleDragEnd,
                              onVerticalDragCancel: _handleDragCancel,
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16.0 * progress),
                                ),
                                child: Material(
                                  color: context.colorScheme.surface,
                                  elevation: progress > 0 ? 8 : 2,
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      if (progress > 0.0)
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          height: screenHeight,
                                          child: Opacity(
                                            opacity: progress.clamp(0.0, 1.0),
                                            child: FullPlayerPage(
                                              onCollapse: _collapse,
                                            ),
                                          ),
                                        ),

                                      if (progress < 0.08)
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          height: _miniPlayerHeight,
                                          child: Opacity(
                                            opacity: (1.0 - progress * 12.0)
                                                .clamp(0.0, 1.0),
                                            child: MiniPlayer(onTap: _expand),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
