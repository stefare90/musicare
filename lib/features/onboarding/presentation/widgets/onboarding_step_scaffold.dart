import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class OnboardingStepScaffold extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? bottomAction;

  const OnboardingStepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.bottomAction,
  });

  @override
  State<OnboardingStepScaffold> createState() => _OnboardingStepScaffoldState();
}

class _OnboardingStepScaffoldState extends State<OnboardingStepScaffold>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.primary.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: context.colorScheme.primary.withValues(
                        alpha: 0.25,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 56,
                    color: context.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                widget.child,
              ],
            ),
          ),
        ),
        if (widget.bottomAction != null) widget.bottomAction!,
      ],
    );
  }
}
