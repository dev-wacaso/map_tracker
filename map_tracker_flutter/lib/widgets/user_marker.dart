import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/user_entry.dart';

class UserMarker extends StatelessWidget {
  final UserEntry user;

  const UserMarker({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(_iconForRole(user.role), size: 28, color: _colorForRole(user.role)),
        if (user.bearing != null)
          Transform.rotate(
            angle: user.bearing! * math.pi / 180,
            child: const Icon(Icons.arrow_upward, size: 12, color: Colors.white),
          ),
      ],
    );
  }

  IconData _iconForRole(String role) => switch (role) {
        'plumber'   => Icons.plumbing,
        'mechanic'  => Icons.build,
        'teacher'   => Icons.school,
        'driver'    => Icons.local_shipping,
        _           => Icons.person_pin,
      };

  Color _colorForRole(String role) => switch (role) {
        'plumber'   => Colors.blue,
        'mechanic'  => Colors.orange,
        'teacher'   => Colors.green,
        'driver'    => Colors.purple,
        _           => Colors.grey,
      };
}
