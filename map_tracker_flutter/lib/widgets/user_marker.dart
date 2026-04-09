import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user_entry.dart';

/// Renders a role-based SVG motorcycle marker.
///
/// The SVG asset is assumed to face **right** (east) by default.
///
/// Bearing logic:
///   - bearing == null  → no rotation, marker faces right (parked / first fix)
///   - bearing 0–180   → rotate clockwise by bearing; motorcycle stays on right side
///   - bearing 181–359 → flip on Y-axis + rotate by (360 - bearing); motorcycle
///                        faces left half without ever going upside-down
class UserMarker extends StatelessWidget {
  final UserEntry user;

  const UserMarker({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      'assets/markers/${user.role}.svg',
      width: 36,
      height: 36,
    );

    if (user.bearing == null) return svg;

    final bearing = user.bearing!;
    final flip = bearing > 180;
    final angle = flip
        ? (360 - bearing) * math.pi / 180
        : bearing * math.pi / 180;

    return Transform.scale(
      scaleX: flip ? -1.0 : 1.0,
      child: Transform.rotate(
        angle: angle,
        child: svg,
      ),
    );
  }
}
