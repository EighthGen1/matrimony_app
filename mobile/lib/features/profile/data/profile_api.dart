import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProfileApiConfig {
  const ProfileApiConfig({
    required this.baseUrl,
    required this.accessToken,
    required this.profileId,
  });

  const ProfileApiConfig.fromEnvironment()
      : baseUrl = const String.fromEnvironment('API_BASE_URL'),
        accessToken =
            kDebugMode ? const String.fromEnvironment('DEV_ACCESS_TOKEN') : '',
        profileId = const String.fromEnvironment('PROFILE_ID');

  final String baseUrl;
  final String accessToken;
  final String profileId;

  bool get isConfigured =>
      baseUrl.isNotEmpty && accessToken.isNotEmpty && profileId.isNotEmpty;
}

class ProfileApiException implements Exception {
  const ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DiscoveryFilters {
  const DiscoveryFilters({
    this.gender,
    this.minAge,
    this.maxAge,
    this.city,
    this.state,
    this.education,
    this.verified,
  });

  final String? gender;
  final int? minAge;
  final int? maxAge;
  final String? city;
  final String? state;
  final String? education;
  final bool? verified;

  Map<String, String> toQueryParameters({required int page}) => {
        'page': '$page',
        if (gender != null) 'gender': gender!,
        if (minAge != null) 'minAge': '$minAge',
        if (maxAge != null) 'maxAge': '$maxAge',
        if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
        if (state != null && state!.trim().isNotEmpty) 'state': state!.trim(),
        if (education != null && education!.trim().isNotEmpty)
          'education': education!.trim(),
        if (verified != null) 'verified': '$verified',
      };
}

class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.gender,
    required this.verified,
    required this.city,
    required this.state,
    required this.education,
    required this.occupation,
    required this.bio,
  });

  final String id;
  final String displayName;
  final int age;
  final String gender;
  final bool verified;
  final String city;
  final String state;
  final String? education;
  final String? occupation;
  final String? bio;

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    final age = json['age'];
    final verified = json['verified'];
    if (age is! int || verified is! bool) {
      throw const FormatException('Discovery profile data is invalid.');
    }
    return DiscoveryProfile(
      id: _requiredString(json, 'id'),
      displayName: _requiredString(json, 'displayName'),
      age: age,
      gender: _requiredString(json, 'gender'),
      verified: verified,
      city: _requiredString(json, 'city'),
      state: _requiredString(json, 'state'),
      education: _optionalString(json, 'education'),
      occupation: _optionalString(json, 'occupation'),
      bio: _optionalString(json, 'bio'),
    );
  }
}

class DiscoveryPage {
  const DiscoveryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<DiscoveryProfile> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory DiscoveryPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final total = json['total'];
    final page = json['page'];
    final pageSize = json['pageSize'];
    final hasMore = json['hasMore'];
    if (items is! List ||
        total is! int ||
        page is! int ||
        pageSize is! int ||
        hasMore is! bool) {
      throw const FormatException('Discovery page data is invalid.');
    }

    return DiscoveryPage(
      items: items.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Discovery profile data is invalid.');
        }
        return DiscoveryProfile.fromJson(item);
      }).toList(growable: false),
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }
}

class ShortlistProfiles {
  const ShortlistProfiles(this.items);

  final List<DiscoveryProfile> items;

  Set<String> get profileIds => items.map((profile) => profile.id).toSet();

  factory ShortlistProfiles.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Shortlist data is invalid.');
    }
    return ShortlistProfiles(
      items.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Shortlist profile data is invalid.');
        }
        return DiscoveryProfile.fromJson(item);
      }).toList(growable: false),
    );
  }
}

class ProfileContact {
  const ProfileContact({required this.phone, required this.email});

  final String phone;
  final String? email;
}

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.gender,
    required this.city,
    required this.state,
    required this.caste,
    required this.education,
    required this.premiumLocked,
    required this.contact,
    required this.shortlisted,
  });

  final String id;
  final String displayName;
  final String gender;
  final String city;
  final String state;
  final String? caste;
  final String? education;
  final bool premiumLocked;
  final ProfileContact? contact;
  final bool shortlisted;

  factory Profile.fromJson(Map<String, dynamic> json) {
    final contactJson = json['contact'];
    final premiumLocked = json['premiumLocked'];
    if (contactJson != null && contactJson is! Map<String, dynamic>) {
      throw const FormatException('Profile contact data is invalid.');
    }
    if (premiumLocked is! bool) {
      throw const FormatException('Profile premium state is invalid.');
    }
    final shortlisted = json['shortlisted'];
    if (shortlisted != null && shortlisted is! bool) {
      throw const FormatException('Profile shortlist state is invalid.');
    }

    return Profile(
      id: _requiredString(json, 'id'),
      displayName: _requiredString(json, 'displayName'),
      gender: _requiredString(json, 'gender'),
      city: _requiredString(json, 'city'),
      state: _requiredString(json, 'state'),
      caste: _optionalString(json, 'caste'),
      education: _optionalString(json, 'education'),
      premiumLocked: premiumLocked,
      shortlisted: shortlisted as bool? ?? false,
      contact: contactJson == null
          ? null
          : ProfileContact(
              phone: _requiredString(contactJson, 'phone'),
              email: _optionalString(contactJson, 'email'),
            ),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Profile field "$key" is missing or invalid.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Profile field "$key" is invalid.');
  }
  return value;
}

class ProfileApiClient {
  ProfileApiClient({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final ProfileApiConfig config;
  final http.Client _client;

  Future<ShortlistProfiles> fetchShortlists() async {
    final response = await _send(
      method: 'GET',
      path: '/api/v1/shortlists',
    );
    if (response.statusCode != 200) {
      _throwResponse(response);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON shortlist.');
      }
      return ShortlistProfiles.fromJson(decoded);
    } on FormatException {
      throw const ProfileApiException(
          'The server returned invalid shortlist data.');
    }
  }

  Future<void> addShortlist(String profileId) =>
      _sendAction('PUT', '/api/v1/shortlists/$profileId');

  Future<void> removeShortlist(String profileId) =>
      _sendAction('DELETE', '/api/v1/shortlists/$profileId');

  Future<void> blockProfile(String profileId) =>
      _sendAction('PUT', '/api/v1/blocks/$profileId');

  Future<void> reportProfile({
    required String profileId,
    required String reason,
    String? details,
  }) async {
    final response = await _send(
      method: 'POST',
      path: '/api/v1/profiles/$profileId/report',
      body: {
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
    if (response.statusCode != 201) _throwResponse(response);
  }

  Future<void> expressInterest(String profileId) async {
    final response = await _send(
      method: 'POST',
      path: '/api/v1/interests',
      body: {'receiverId': profileId},
    );
    if (response.statusCode != 201) _throwResponse(response);
  }

  Future<void> _sendAction(String method, String path) async {
    final response = await _send(method: method, path: path);
    if (response.statusCode != 204) _throwResponse(response);
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, Object?>? body,
  }) async {
    if (!config.isConfigured) {
      throw const ProfileApiException('Profile API is not configured.');
    }
    final baseUri = Uri.tryParse(config.baseUrl);
    if (baseUri == null ||
        !baseUri.hasAuthority ||
        (baseUri.scheme != 'http' && baseUri.scheme != 'https')) {
      throw const ProfileApiException('Profile API URL is invalid.');
    }
    final uri = baseUri.replace(path: path);
    try {
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${config.accessToken}',
        if (body != null) 'Content-Type': 'application/json',
      };
      switch (method) {
        case 'GET':
          return await _client.get(uri, headers: headers);
        case 'PUT':
          return await _client.put(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'DELETE':
          return await _client.delete(uri, headers: headers);
        case 'POST':
          return await _client.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        default:
          throw ArgumentError.value(
              method, 'method', 'Unsupported HTTP method');
      }
    } on http.ClientException {
      throw const ProfileApiException(
          'Could not connect to the profile server.');
    }
  }

  Never _throwResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw const ProfileApiException(
        'Your sign-in has expired or is invalid. Sign in again.',
      );
    }
    if (response.statusCode == 404) {
      throw const ProfileApiException('This profile could not be found.');
    }
    if (response.statusCode == 409) {
      throw const ProfileApiException(
        'This action is unavailable or has already been completed.',
      );
    }
    throw ProfileApiException(
      'The profile server returned an error (${response.statusCode}).',
    );
  }

  Future<DiscoveryPage> fetchDiscovery({
    int page = 1,
    DiscoveryFilters filters = const DiscoveryFilters(),
  }) async {
    if (!config.isConfigured) {
      throw const ProfileApiException('Profile API is not configured.');
    }
    final baseUri = Uri.tryParse(config.baseUrl);
    if (baseUri == null ||
        !baseUri.hasAuthority ||
        (baseUri.scheme != 'http' && baseUri.scheme != 'https')) {
      throw const ProfileApiException('Profile API URL is invalid.');
    }

    late final http.Response response;
    try {
      response = await _client.get(
        baseUri.replace(
          path: '/api/v1/profiles',
          queryParameters: filters.toQueryParameters(page: page),
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${config.accessToken}',
        },
      );
    } on http.ClientException {
      throw const ProfileApiException(
          'Could not connect to the profile server.');
    }

    if (response.statusCode == 401) {
      throw const ProfileApiException(
        'Your sign-in has expired or is invalid. Sign in again to browse profiles.',
      );
    }
    if (response.statusCode != 200) {
      throw ProfileApiException(
        'The discovery server returned an error (${response.statusCode}).',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON discovery page.');
      }
      return DiscoveryPage.fromJson(decoded);
    } on FormatException {
      throw const ProfileApiException(
          'The discovery server returned invalid data.');
    }
  }

  Future<Profile> fetchProfile() async {
    if (!config.isConfigured) {
      throw const ProfileApiException('Profile API is not configured.');
    }

    final baseUri = Uri.tryParse(config.baseUrl);
    if (baseUri == null ||
        !baseUri.hasAuthority ||
        (baseUri.scheme != 'http' && baseUri.scheme != 'https')) {
      throw const ProfileApiException('Profile API URL is invalid.');
    }

    final uri = baseUri.resolve(
      '/api/v1/profiles/${Uri.encodeComponent(config.profileId)}',
    );

    late final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${config.accessToken}',
        },
      );
    } on http.ClientException {
      throw const ProfileApiException(
          'Could not connect to the profile server.');
    }

    if (response.statusCode == 401) {
      throw const ProfileApiException(
        'Your sign-in has expired or is invalid. Sign in again to reload the profile.',
      );
    }
    if (response.statusCode == 404) {
      throw const ProfileApiException('This profile could not be found.');
    }
    if (response.statusCode != 200) {
      throw ProfileApiException(
        'The profile server returned an error (${response.statusCode}).',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON profile object.');
      }
      return Profile.fromJson(decoded);
    } on FormatException {
      throw const ProfileApiException(
          'The profile server returned invalid data.');
    }
  }

  void close() => _client.close();
}
