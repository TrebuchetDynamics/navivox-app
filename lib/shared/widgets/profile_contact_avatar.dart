import 'package:flutter/material.dart';

import '../../core/channel/navivox_channel.dart';
import '../presentation/profile_contact_avatar_presentation.dart';

const _telegramAvatarGradients = <List<Color>>[
  [Color(0xff5ac8fa), Color(0xff007aff)],
  [Color(0xffff9500), Color(0xffff2d55)],
  [Color(0xff34c759), Color(0xff009688)],
  [Color(0xffaf52de), Color(0xff5856d6)],
  [Color(0xffffcc00), Color(0xffff6b00)],
  [Color(0xff64d2ff), Color(0xff0a84ff)],
];

class ProfileContactAvatar extends StatelessWidget {
  const ProfileContactAvatar({super.key, required this.contact, this.radius});

  final NavivoxProfileContact contact;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final presentation = ProfileContactAvatarPresentation(contact);
    final effectiveRadius = radius ?? 22;
    final gradient =
        _telegramAvatarGradients[presentation.colorIndex %
            _telegramAvatarGradients.length];

    return Semantics(
      label: presentation.semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: effectiveRadius * 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Center(
            child: Text(
              presentation.initial,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
