import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({this.height = 16, super.key});

  final double height;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: 0.45 + (_controller.value * 0.5),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      },
    );
  }
}
