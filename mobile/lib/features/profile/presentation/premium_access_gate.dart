import 'dart:ui';

import 'package:flutter/material.dart';
import '../domain/profile_access.dart';
import '../../../l10n/app_localizations.dart';

class PremiumAccessGate extends StatelessWidget {
  const PremiumAccessGate({
    required this.viewingOwnProfile,
    required this.entitlement,
    required this.premiumContent,
    required this.lockedPreview,
    required this.onUpgrade,
    super.key,
  });

  final bool viewingOwnProfile;
  final Entitlement? entitlement;
  final Widget premiumContent;
  final Widget lockedPreview;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final unlocked = ProfileAccess.canViewPremium(
      viewingOwnProfile: viewingOwnProfile,
      viewerEntitlement: entitlement,
    );

    if (unlocked) return premiumContent;

    final strings = AppLocalizations.of(context)!;
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ExcludeSemantics(child: lockedPreview),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: Color(0x99000000)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.premiumRequired,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onUpgrade,
                  child: Text(strings.upgrade),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
