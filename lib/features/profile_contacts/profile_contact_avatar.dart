import 'package:flutter/material.dart';

import '../../core/channel/navivox_channel.dart';
import 'profile_contact_presentation.dart';

class ProfileContactAvatar extends StatelessWidget {
  const ProfileContactAvatar({super.key, required this.contact, this.radius});

  final NavivoxProfileContact contact;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final presentation = ProfileContactPresentation(contact);
    final color = Colors
        .primaries[presentation.avatarColorIndex % Colors.primaries.length]
        .shade700;

    return Semantics(
      label: presentation.avatarSemanticLabel,
      image: true,
      excludeSemantics: true,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Text(presentation.avatarInitial),
      ),
    );
  }
}
