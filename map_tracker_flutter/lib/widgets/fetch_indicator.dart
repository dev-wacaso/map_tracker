import 'package:flutter/material.dart';

/// Small orb overlaid on the map (upper-right).
/// Pulses with a red glow while fetching; flat gray when idle.
class FetchIndicator extends StatefulWidget {
  final bool isFetching;

  const FetchIndicator({super.key, required this.isFetching});

  @override
  State<FetchIndicator> createState() => _FetchIndicatorState();
}

class _FetchIndicatorState extends State<FetchIndicator>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glow = Tween<double>(begin: 2, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isFetching) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(FetchIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFetching && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isFetching && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFetching) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.7),
              blurRadius: _glow.value,
              spreadRadius: _glow.value / 3,
            ),
          ],
        ),
      ),
    );
  }
}
