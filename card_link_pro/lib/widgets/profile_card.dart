// lib/widgets/profile_card.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/profile.dart';

/// A compact profile card with optional background image/color and
/// contrast-aware foreground.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    this.height = 220,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.showContactRows = true,
  });

  final Profile profile;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool showContactRows;

  @override
  Widget build(BuildContext context) {
    final bool hasBg = (profile.backgroundPath ?? '').isNotEmpty;
    final Color bgColor = profile.backgroundColor ?? Colors.grey.shade200;

    // Pick foreground colour for readability
    final Color foreground = hasBg
        ? Colors.white
        : (ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
            ? Colors.white
            : Colors.black87);

    final Widget background = hasBg
        ? ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                (profile.backgroundPath!.startsWith('assets/')
                    ? Image.asset(profile.backgroundPath!, fit: BoxFit.cover)
                    : Image.file(File(profile.backgroundPath!),
                        fit: BoxFit.cover)),
                // Old: withOpacity(0.35) → New API:
                Container(color: Colors.black.withValues(alpha: 0.35)),
              ],
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
            ),
          );

    final ImageProvider? avatarProvider = (profile.avatarPath ?? '').isNotEmpty
        ? (profile.avatarPath!.startsWith('assets/')
            ? AssetImage(profile.avatarPath!)
            : FileImage(File(profile.avatarPath!)) as ImageProvider)
        : null;

    return Material(
      elevation: 2,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: background),
            Padding(
              padding: padding,
              child: DefaultTextStyle(
                style: TextStyle(color: foreground),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? Text(
                                  profile.fullName.isNotEmpty
                                      ? profile.fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      fontSize: 26, color: foreground),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: foreground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (profile.role.isNotEmpty)
                                Text(
                                  profile.role,
                                  style: TextStyle(
                                    fontSize: 13,
                                    // Old: foreground.withOpacity(0.8)
                                    // New:
                                    color: foreground.withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (showContactRows) ...[
                      _row(
                          icon: Icons.phone,
                          text: profile.phone,
                          color: foreground),
                      const SizedBox(height: 4),
                      _row(
                          icon: Icons.email,
                          text: profile.email,
                          color: foreground),
                      const SizedBox(height: 4),
                      _row(
                          icon: Icons.link,
                          text: profile.website,
                          color: foreground),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              // Old: color.withOpacity(0.9) → New:
              color: color.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
