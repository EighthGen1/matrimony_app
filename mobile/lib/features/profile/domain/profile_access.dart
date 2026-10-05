class Entitlement {
  const Entitlement({
    required this.verifiedByStore,
    required this.startsAt,
    required this.expiresAt,
  });

  final bool verifiedByStore;
  final DateTime startsAt;
  final DateTime expiresAt;

  DateTime get graceEndsAt => expiresAt.add(const Duration(days: 3));

  bool isActiveAt(DateTime now) => verifiedByStore &&
      !now.isBefore(startsAt) &&
      now.isBefore(graceEndsAt);

  bool isInGracePeriodAt(DateTime now) =>
      verifiedByStore && !now.isBefore(expiresAt) && now.isBefore(graceEndsAt);
}

class ProfileAccess {
  const ProfileAccess._();

  static bool canViewPremium({
    required bool viewingOwnProfile,
    required Entitlement? viewerEntitlement,
    DateTime? now,
  }) {
    if (viewingOwnProfile) return true;
    final currentTime = now ?? DateTime.now().toUtc();
    return viewerEntitlement?.isActiveAt(currentTime) ?? false;
  }
}
