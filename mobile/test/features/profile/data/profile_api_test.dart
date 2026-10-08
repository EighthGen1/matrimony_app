import 'dart:convert';

import 'package:anbu_matrimony/features/profile/data/profile_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const config = ProfileApiConfig(
    baseUrl: 'http://localhost:3000',
    accessToken: 'test-access-token',
    profileId: '7a27ef52-6aa7-49c2-a9ec-e4708866993b',
  );

  test('fetches and parses a profile using the authenticated API', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'http://localhost:3000/api/v1/profiles/${config.profileId}',
      );
      expect(request.headers['authorization'], 'Bearer test-access-token');

      return http.Response(
        jsonEncode({
          'id': config.profileId,
          'displayName': 'Test D.',
          'gender': 'other',
          'city': 'Test City',
          'state': 'Test State',
          'caste': null,
          'education': null,
          'premiumLocked': false,
          'contact': {'phone': '+999000000001', 'email': null},
        }),
        200,
      );
    });
    final api = ProfileApiClient(config: config, client: client);

    final profile = await api.fetchProfile();

    expect(profile.displayName, 'Test D.');
    expect(profile.city, 'Test City');
    expect(profile.contact?.phone, '+999000000001');
    api.close();
  });

  test('requires API settings before making a request', () async {
    final api = ProfileApiClient(
      config: const ProfileApiConfig(
        baseUrl: '',
        accessToken: '',
        profileId: '',
      ),
      client: MockClient((_) async => http.Response('', 500)),
    );

    await expectLater(
      api.fetchProfile(),
      throwsA(isA<ProfileApiException>()),
    );
    api.close();
  });

  test('reports an expired or invalid access token', () async {
    final api = ProfileApiClient(
      config: config,
      client: MockClient(
          (_) async => http.Response('{"error":"INVALID_ACCESS_TOKEN"}', 401)),
    );

    await expectLater(
      api.fetchProfile(),
      throwsA(
        isA<ProfileApiException>().having(
          (error) => error.message,
          'message',
          contains('Sign in again'),
        ),
      ),
    );
    api.close();
  });

  test('fetches paginated discovery results with server-side filters',
      () async {
    final filters = const DiscoveryFilters(
      gender: 'female',
      minAge: 25,
      maxAge: 35,
      city: 'Chennai',
      verified: true,
    );
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/profiles');
      expect(request.url.queryParameters['page'], '2');
      expect(request.url.queryParameters['gender'], 'female');
      expect(request.url.queryParameters['minAge'], '25');
      expect(request.url.queryParameters['maxAge'], '35');
      expect(request.url.queryParameters['city'], 'Chennai');
      expect(request.url.queryParameters['verified'], 'true');
      expect(request.headers['authorization'], 'Bearer test-access-token');

      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'f1f3c857-7318-47e7-a1aa-3c06fed4de3f',
              'displayName': 'Nila S.',
              'age': 29,
              'gender': 'female',
              'verified': true,
              'city': 'Chennai',
              'state': 'Tamil Nadu',
              'education': 'M.Sc. Mathematics',
              'occupation': 'Data Analyst',
              'bio': 'Fictional development profile.',
            },
          ],
          'total': 21,
          'page': 2,
          'pageSize': 20,
          'hasMore': false,
          'sort': 'newest',
        }),
        200,
      );
    });
    final api = ProfileApiClient(config: config, client: client);

    final result = await api.fetchDiscovery(page: 2, filters: filters);

    expect(result.total, 21);
    expect(result.hasMore, isFalse);
    expect(result.items.single.displayName, 'Nila S.');
    expect(result.items.single.verified, isTrue);
    api.close();
  });

  test('adds a profile to the shortlist through the authenticated API',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/v1/shortlists/${config.profileId}');
      expect(request.headers['authorization'], 'Bearer test-access-token');
      return http.Response('', 204);
    });
    final api = ProfileApiClient(config: config, client: client);

    await api.addShortlist(config.profileId);

    api.close();
  });

  test('reports duplicate shortlist actions instead of masking them',
      () async {
    final api = ProfileApiClient(
      config: config,
      client: MockClient((_) async => http.Response(
            '{"error":"PROFILE_UNAVAILABLE_OR_SHORTLISTED"}',
            409,
          )),
    );

    await expectLater(
      api.addShortlist(config.profileId),
      throwsA(
        isA<ProfileApiException>().having(
          (error) => error.message,
          'message',
          contains('already been completed'),
        ),
      ),
    );
    api.close();
  });
}
