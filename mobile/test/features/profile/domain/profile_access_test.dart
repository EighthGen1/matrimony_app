import 'package:flutter_test/flutter_test.dart';
import 'package:anbu_matrimony/features/profile/domain/profile_access.dart';

void main() {
  group('ProfileAccess', () {
    final now = DateTime.utc(2026, 10, 5);

    test('requires a store-verified entitlement', () {
      final entitlement = Entitlement(
        verifiedByStore: false,
        startsAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 89)),
      );

      expect(ProfileAccess.canViewPremium(
        viewingOwnProfile: false,
        viewerEntitlement: entitlement,
        now: now,
      ), isFalse);
    });

    test('allows active 90-day pass and the configured three-day grace', () {
      final expires = now.add(const Duration(days: 1));
      final entitlement = Entitlement(
        verifiedByStore: true,
        startsAt: now.subtract(const Duration(days: 89)),
        expiresAt: expires,
      );

      expect(ProfileAccess.canViewPremium(
        viewingOwnProfile: false,
        viewerEntitlement: entitlement,
        now: now,
      ), isTrue);
      expect(entitlement.isInGracePeriodAt(expires.add(const Duration(days: 1))), isTrue);
      expect(entitlement.isActiveAt(expires.add(const Duration(days: 3))), isFalse);
    });

    test('always lets a member view their own profile', () {
      expect(ProfileAccess.canViewPremium(
        viewingOwnProfile: true,
        viewerEntitlement: null,
        now: now,
      ), isTrue);
    });
  });
}
