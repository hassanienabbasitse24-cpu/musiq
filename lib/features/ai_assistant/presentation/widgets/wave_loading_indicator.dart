import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WaveLoadingIndicator extends StatefulWidget {
  final int barCount;
  final double barWidth;
  final double maxBarHeight;
  final Duration duration;

  const WaveLoadingIndicator({
    super.key,
    this.barCount = 5,
    this.barWidth = 4,
    this.maxBarHeight = 30,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<WaveLoadingIndicator> createState() => _WaveLoadingIndicatorState();
}

class _WaveLoadingIndicatorState extends State<WaveLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (index) {
            final height = _getBarHeight(index);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: EdgeInsets.symmetric(horizontal: widget.barWidth * 0.4),
              width: widget.barWidth,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.barWidth / 2),
                gradient: AppColors.accentGradient,
              ),
            );
          }),
        );
      },
    );
  }

  double _getBarHeight(int index) {
    final sine = sin((_controller.value * 2 * pi) + (index * 0.8));
    final normalized = (sine + 1) / 2;
    return 6 + normalized * (widget.maxBarHeight - 6);
  }
}
