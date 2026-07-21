import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_session.dart';

class ProviderSummary {
  const ProviderSummary({
    required this.id,
    required this.name,
    required this.subtitle,
    this.description,
    this.imageUrl,
    this.address,
    this.latitude,
    this.longitude,
  });
  final String id;
  final String name;
  final String subtitle;
  final String? description;
  final String? imageUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  factory ProviderSummary.fromJson(
    Map<String, dynamic> json,
    String baseUrl,
  ) => ProviderSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    address: json['address'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    imageUrl: _absoluteUrl(
      baseUrl,
      (json['images'] as List<dynamic>?)?.isNotEmpty == true
          ? ((json['images'] as List<dynamic>).first
                    as Map<String, dynamic>)['url']
                as String?
          : null,
    ),
    subtitle:
        '${json['area']?['name'] ?? 'قنا'}${json['isVerified'] == true ? ' · موثق' : ''}${(json['rating'] as num? ?? 0) > 0 ? ' · ${json['rating']} ★' : ''}',
  );
}

class ProviderDetails {
  const ProviderDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.reviews,
    required this.phone,
    required this.whatsapp,
    this.socialPlatform,
    this.socialUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.areaName,
    required this.isVerified,
    required this.openingTime,
    required this.closingTime,
    required this.services,
    required this.offers,
    required this.viewerFavorite,
    this.kidFriendly = false,
    this.accessible = false,
    this.hasParking = false,
    this.acceptsCards = false,
    this.homeService = false,
    this.needsBooking = false,
    this.open24h = false,
    this.hasDelivery = false,
  });
  final String id;
  final String name;
  final String? description;
  final List<String> images;
  final List<Map<String, dynamic>> reviews;
  final String? phone;
  final String? whatsapp;
  final String? socialPlatform;
  final String? socialUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String areaName;
  final bool isVerified;
  final String? openingTime;
  final String? closingTime;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> offers;
  final bool viewerFavorite;
  final bool kidFriendly;
  final bool accessible;
  final bool hasParking;
  final bool acceptsCards;
  final bool homeService;
  final bool needsBooking;
  final bool open24h;
  final bool hasDelivery;
  factory ProviderDetails.fromJson(Map<String, dynamic> json, String baseUrl) =>
      ProviderDetails(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        images: (json['images'] as List<dynamic>? ?? [])
            .map(
              (item) => _absoluteUrl(
                baseUrl,
                (item as Map<String, dynamic>)['url'] as String?,
              ),
            )
            .whereType<String>()
            .toList(),
        reviews: (json['reviews'] as List<dynamic>? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        phone: json['phone'] as String?,
        whatsapp: json['whatsapp'] as String?,
        socialPlatform: json['socialPlatform'] as String?,
        socialUrl: json['socialUrl'] as String?,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        areaName: json['area']?['name'] as String? ?? 'قنا',
        isVerified: json['isVerified'] as bool? ?? false,
        openingTime: json['openingTime'] as String?,
        closingTime: json['closingTime'] as String?,
        services: (json['services'] as List<dynamic>? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        offers: (json['offers'] as List<dynamic>? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        viewerFavorite:
            (json['viewer'] as Map<String, dynamic>?)?['favorite'] as bool? ??
            false,
        kidFriendly: json['kidFriendly'] as bool? ?? false,
        accessible: json['accessible'] as bool? ?? false,
        hasParking: json['hasParking'] as bool? ?? false,
        acceptsCards: json['acceptsCards'] as bool? ?? false,
        homeService: json['homeService'] as bool? ?? false,
        needsBooking: json['needsBooking'] as bool? ?? false,
        open24h: json['open24h'] as bool? ?? false,
        hasDelivery: json['hasDelivery'] as bool? ?? false,
      );
}

class CategoryOption {
  const CategoryOption({required this.id, required this.name, this.slug});
  final String id;
  final String name;
  final String? slug;
  factory CategoryOption.fromJson(Map<String, dynamic> json) =>
      CategoryOption(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String?,
      );
}

class AreaOption {
  const AreaOption({required this.id, required this.name});
  final String id;
  final String name;
  factory AreaOption.fromJson(Map<String, dynamic> json) =>
      AreaOption(id: json['id'] as String, name: json['name'] as String);
}

String? _absoluteUrl(String baseUrl, String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = Uri.tryParse(value);
  if (parsed?.hasScheme == true) return value;
  return '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/${value.replaceFirst(RegExp(r'^/'), '')}';
}

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://henaqena.maalsoft.com',
          );
  final String baseUrl;

  Future<void> _cacheSet(String key, List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_$key', jsonEncode(data));
    } catch (e) {
      // Cache failure is non-fatal
    }
  }

  Future<List<dynamic>?> _cacheGet(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cache_$key');
      return cached != null ? jsonDecode(cached) as List<dynamic> : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) await prefs.remove(key);
      }
    } catch (e) {
      // Ignore cache clear errors
    }
  }

  Future<List<Map<String, dynamic>>> fetchAds({String? areaId}) async {
    final uri = Uri.parse(
      '$baseUrl/api/ads',
    ).replace(queryParameters: {'areaId': ?areaId});
    final response = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List<dynamic>).map((item) {
      final ad = Map<String, dynamic>.from(item as Map);
      ad['imageUrl'] = _absoluteUrl(baseUrl, ad['imageUrl'] as String?);
      return ad;
    }).toList();
  }

  Future<Map<String, dynamic>> toggleAdReaction(String adId) async {
    final response = await http
        .post(Uri.parse('$baseUrl/api/ads/$adId/react'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('ad_reaction_error');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<List<Map<String, dynamic>>> fetchPrices({String? areaId}) async {
    final uri = Uri.parse(
      '$baseUrl/api/prices',
    ).replace(queryParameters: {'areaId': ?areaId});
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchOffers({String? areaId}) async {
    final uri = Uri.parse(
      '$baseUrl/api/offers',
    ).replace(queryParameters: {'areaId': ?areaId});
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) throw Exception('offers_error');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchNow({String? areaId}) async {
    final uri = Uri.parse(
      '$baseUrl/api/now',
    ).replace(queryParameters: {'areaId': ?areaId});
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> toggleNowHelpful(String id) async {
    final response = await http
        .post(Uri.parse('$baseUrl/api/now/$id/helpful'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('now_helpful_error');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Map<String, String> get _jsonHeaders => {
    'content-type': 'application/json',
    if (AuthSession.isSignedIn) 'authorization': 'Bearer ${AuthSession.token}',
  };
  Map<String, String> get _adminHeaders => {
    'content-type': 'application/json',
    if (AuthSession.adminToken != null)
      'authorization': 'Bearer ${AuthSession.adminToken}',
  };

  Future<void> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/admin/auth/login'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_login_error');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final admin = body['admin'] as Map<String, dynamic>;
    await AuthSession.saveAdmin(
      newToken: body['token'] as String,
      userName: admin['name'] as String,
      role: admin['role'] as String,
    );
  }

  Future<void> adminLogout() async {
    await http
        .post(
          Uri.parse('$baseUrl/api/admin/auth/logout'),
          headers: _adminHeaders,
        )
        .timeout(const Duration(seconds: 5));
    await AuthSession.clearAdmin();
  }

  Future<List<Map<String, dynamic>>> fetchAdminProviders() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admin/providers'), headers: _adminHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_error');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> moderateAdminProvider({
    required String id,
    required String status,
    String? note,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/admin/providers/$id'),
          headers: _adminHeaders,
          body: jsonEncode({
            'status': status,
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_moderation_error');
  }

  Future<void> updateAdminProviderContent(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/admin/providers/$id/content'),
          headers: _adminHeaders,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_update_error');
  }

  Future<List<Map<String, dynamic>>> fetchAdminListings() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admin/listings'), headers: _adminHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_error');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> moderateAdminListing({
    required String id,
    required String status,
    String? note,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/admin/listings/$id'),
          headers: _adminHeaders,
          body: jsonEncode({
            'status': status,
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_moderation_error');
  }

  Future<void> updateAdminListingContent(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/admin/listings/$id/content'),
          headers: _adminHeaders,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_update_error');
  }

  Future<List<Map<String, dynamic>>> _fetchAdminQueue(String path) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admin/$path'), headers: _adminHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_error');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _moderateAdminQueue({
    required String path,
    required String id,
    required String status,
    String? note,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/admin/$path/$id'),
          headers: _adminHeaders,
          body: jsonEncode({
            'status': status,
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_moderation_error');
  }

  Future<List<Map<String, dynamic>>> fetchAdminReviews() =>
      _fetchAdminQueue('reviews?status=PENDING');
  Future<List<Map<String, dynamic>>> fetchAdminReplies() =>
      _fetchAdminQueue('replies');
  Future<List<Map<String, dynamic>>> fetchAdminProviderReports() =>
      _fetchAdminQueue('provider-reports');
  Future<List<Map<String, dynamic>>> fetchAdminListingReports() =>
      _fetchAdminQueue('listing-reports');
  Future<List<Map<String, dynamic>>> fetchAdminSupportTickets() =>
      _fetchAdminQueue('support-tickets');

  Future<void> moderateAdminReview({
    required String id,
    required String status,
    String? note,
  }) =>
      _moderateAdminQueue(path: 'reviews', id: id, status: status, note: note);
  Future<void> moderateAdminReply({
    required String id,
    required String status,
    String? note,
  }) =>
      _moderateAdminQueue(path: 'replies', id: id, status: status, note: note);
  Future<void> moderateAdminProviderReport({
    required String id,
    required String status,
  }) => _moderateAdminQueue(path: 'provider-reports', id: id, status: status);
  Future<void> moderateAdminListingReport({
    required String id,
    required String status,
  }) => _moderateAdminQueue(path: 'listing-reports', id: id, status: status);
  Future<void> moderateAdminSupportTicket({
    required String id,
    required String status,
  }) => _moderateAdminQueue(path: 'support-tickets', id: id, status: status);

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/register'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'name': name,
            'phone': phone,
            'password': password,
            if (email != null && email.isNotEmpty) 'email': email,
          }),
        )
        .timeout(const Duration(seconds: 8));
    await _saveAuthenticatedSession(response);
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: _jsonHeaders,
          body: jsonEncode({'identifier': identifier, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));
    await _saveAuthenticatedSession(response);
  }

  Future<void> federatedLogin({
    required String provider,
    required String identityToken,
    String? authorizationCode,
    String? displayName,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/federated'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'provider': provider,
            'identityToken': identityToken,
            if (authorizationCode?.isNotEmpty == true)
              'authorizationCode': authorizationCode,
            if (displayName?.trim().isNotEmpty == true)
              'displayName': displayName!.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));
    await _saveAuthenticatedSession(response);
  }

  Future<void> requestPasswordReset({
    required String identifier,
    required String channel,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/password-reset/request'),
          headers: _jsonHeaders,
          body: jsonEncode({'identifier': identifier, 'channel': channel}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('reset_request_error');
  }

  Future<Map<String, dynamic>> requestVerification(String channel) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/verification/request'),
          headers: _jsonHeaders,
          body: jsonEncode({'channel': channel}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) {
      throw Exception('verification_request_error');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> confirmVerification(String channel, String code) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/verification/confirm'),
          headers: _jsonHeaders,
          body: jsonEncode({'channel': channel, 'code': code.trim()}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('verification_confirm_error');
    }
  }

  Future<void> confirmPasswordReset({
    required String identifier,
    required String channel,
    required String code,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/password-reset/confirm'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'identifier': identifier,
            'channel': channel,
            'code': code,
            'newPassword': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('reset_confirm_error');
  }

  Future<void> _saveAuthenticatedSession(http.Response response) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        response.statusCode == 401 ? 'invalid_credentials' : 'auth_error',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await AuthSession.save(
      newToken: body['token'] as String,
      userName: (body['user'] as Map<String, dynamic>)['name'] as String,
    );
    final admin = body['admin'] as Map<String, dynamic>?;
    if (admin != null) {
      await AuthSession.saveAdmin(
        newToken: admin['token'] as String,
        userName: admin['name'] as String,
        role: admin['role'] as String,
      );
    }
  }

  Future<List<CategoryOption>> fetchCategories({bool skipCache = false}) async {
    const cacheKey = 'categories';
    if (!skipCache) {
      final cached = await _cacheGet(cacheKey);
      if (cached != null) {
        return (cached as List<dynamic>)
            .map((item) => CategoryOption.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    final response = await http
        .get(Uri.parse('$baseUrl/api/categories'))
        .timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    await _cacheSet(cacheKey, data);
    return data
        .map((item) => CategoryOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AreaOption>> fetchAreas({bool skipCache = false}) async {
    const cacheKey = 'areas';
    if (!skipCache) {
      final cached = await _cacheGet(cacheKey);
      if (cached != null) {
        return (cached as List<dynamic>)
            .map((item) => AreaOption.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    final response = await http
        .get(Uri.parse('$baseUrl/api/areas'))
        .timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    await _cacheSet(cacheKey, data);
    return data
        .map((item) => AreaOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitProvider({required Map<String, dynamic> data}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/providers'),
          headers: _jsonHeaders,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 409) throw Exception('duplicate');
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) {
      throw Exception('API error ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> uploadProviderImages(
    List<XFile> images,
  ) async {
    if (!AuthSession.isSignedIn) throw Exception('unauthorized');
    final payload = <Map<String, String>>[];
    for (final image in images) {
      final path = image.path.toLowerCase();
      final mimeType = path.endsWith('.png')
          ? 'image/png'
          : path.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
      payload.add({
        'base64': base64Encode(await image.readAsBytes()),
        'mimeType': mimeType,
      });
    }
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/uploads/provider-images'),
          headers: _jsonHeaders,
          body: jsonEncode({'images': payload}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('upload_error');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['images'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<String> uploadAvatar(XFile image) async {
    final path = image.path.toLowerCase();
    final mimeType = path.endsWith('.png')
        ? 'image/png'
        : path.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/uploads/avatar'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'base64': base64Encode(await image.readAsBytes()),
            'mimeType': mimeType,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 201) throw Exception('avatar_upload_error');
    return (jsonDecode(response.body) as Map<String, dynamic>)['url'] as String;
  }

  Future<void> updateProfile({
    required String name,
    String? email,
    String? avatarUrl,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/me/profile'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'name': name.trim(),
            'email': email?.trim() ?? '',
            'avatarUrl': ?avatarUrl,
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('profile_update_error');
  }

  Future<void> submitProviderReport({
    required Map<String, dynamic> data,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/provider-reports'),
          headers: _jsonHeaders,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) {
      throw Exception('API error ${response.statusCode}');
    }
  }

  Future<List<ProviderSummary>> fetchProviders({
    String? areaId,
    String? category,
    String? searchQuery,
    int page = 1,
    bool verifiedOnly = false,
    bool openNow = false,
    bool hasDelivery = false,
    bool hasParking = false,
    bool acceptsCards = false,
    String sort = 'name',
    bool skipCache = false,
  }) async {
    final cacheKey = 'providers_${areaId}_${category}_${searchQuery}_${page}_${verifiedOnly}_${openNow}_${hasDelivery}_${hasParking}_${acceptsCards}_${sort}';
    if (!skipCache) {
      final cached = await _cacheGet(cacheKey);
      if (cached != null) {
        return (cached as List<dynamic>)
            .map((item) => ProviderSummary.fromJson(item as Map<String, dynamic>, baseUrl))
            .toList();
      }
    }

    final params = <String, String>{
      ...?(areaId == null ? null : {'areaId': areaId}),
      ...?(category == null ? null : {'category': category}),
      ...?(searchQuery == null || searchQuery.trim().isEmpty
          ? null
          : {'q': searchQuery.trim()}),
      'page': '$page',
      if (verifiedOnly) 'verified': 'true',
      if (openNow) 'openNow': 'true',
      if (hasDelivery) 'hasDelivery': 'true',
      if (hasParking) 'hasParking': 'true',
      if (acceptsCards) 'acceptsCards': 'true',
      'sort': sort,
    };
    final uri = Uri.parse(
      '$baseUrl/api/providers',
    ).replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    await _cacheSet(cacheKey, data);
    return data
        .map(
          (item) =>
              ProviderSummary.fromJson(item as Map<String, dynamic>, baseUrl),
        )
        .toList();
  }

  Future<ProviderDetails> fetchProvider(String id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/providers/$id'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    return ProviderDetails.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
      baseUrl,
    );
  }

  Future<void> submitReview({
    required String providerId,
    required int quality,
    required int commitment,
    required int value,
    String? comment,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/reviews'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'providerId': providerId,
            'quality': quality,
            'commitment': commitment,
            'value': value,
            if (comment != null && comment.trim().isNotEmpty)
              'comment': comment.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode == 409) throw Exception('duplicate_review');
    if (response.statusCode != 201) throw Exception('review_error');
  }

  Future<void> updateReview({
    required String reviewId,
    required int quality,
    required int commitment,
    required int value,
    String? comment,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/me/reviews/$reviewId'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'quality': quality,
            'commitment': commitment,
            'value': value,
            if (comment != null && comment.trim().isNotEmpty)
              'comment': comment.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('review_error');
  }

  Future<Map<String, dynamic>> toggleReviewHelpful(String reviewId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/reviews/$reviewId/helpful'),
          headers: _jsonHeaders,
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('review_helpful_error');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> replyToReview(String reviewId, String text) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/reviews/$reviewId/replies'),
          headers: _jsonHeaders,
          body: jsonEncode({'text': text.trim()}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('review_reply_error');
  }

  Future<Map<String, dynamic>> toggleProviderFavorite(
    String providerId, {
    String? listId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/providers/$providerId/favorite'),
          headers: _jsonHeaders,
          body: jsonEncode({'listId': ?listId}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('favorite_error');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<List<Map<String, dynamic>>> fetchFavoriteLists() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/me/favorite-lists'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('favorite_lists_error');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createFavoriteList(String name) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/me/favorite-lists'),
          headers: _jsonHeaders,
          body: jsonEncode({'name': name.trim()}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('favorite_list_create_error');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> renameFavoriteList(String id, String name) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/me/favorite-lists/$id'),
          headers: _jsonHeaders,
          body: jsonEncode({'name': name.trim()}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('favorite_list_rename_error');
  }

  Future<void> deleteFavoriteList(String id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/api/me/favorite-lists/$id'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('favorite_list_delete_error');
  }

  Future<List<Map<String, dynamic>>> fetchListings({
    String? areaId,
    String? category,
    String? query,
    bool skipCache = false,
  }) async {
    final cacheKey = 'listings_${areaId}_${category}_${query}';
    if (!skipCache) {
      final cached = await _cacheGet(cacheKey);
      if (cached != null) {
        return (cached as List<dynamic>)
            .map((item) => _normalizeMedia(Map<String, dynamic>.from(item as Map<String, dynamic>)))
            .toList();
      }
    }

    final uri = Uri.parse('$baseUrl/api/listings').replace(
      queryParameters: {
        'areaId': ?areaId,
        if (category != null && category.isNotEmpty) 'category': category,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) throw Exception('listings_error');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>)
        .map((item) => _normalizeMedia(Map<String, dynamic>.from(item as Map)))
        .toList();
    await _cacheSet(cacheKey, data);
    return data;
  }

  Future<Map<String, dynamic>> fetchListing(String id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/listings/$id'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) throw Exception('listing_error');
    return _normalizeMedia(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Map<String, dynamic> _normalizeMedia(Map<String, dynamic> item) {
    final images = item['images'] as List<dynamic>?;
    if (images != null) {
      item['images'] = images.map((value) {
        final image = Map<String, dynamic>.from(value as Map);
        image['url'] = _absoluteUrl(baseUrl, image['url'] as String?);
        return image;
      }).toList();
    }
    return item;
  }

  Future<void> reportListing(String id, String reason) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/listings/$id/reports'),
          headers: _jsonHeaders,
          body: jsonEncode({'reason': reason.trim()}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('listing_report_error');
  }

  Future<Map<String, dynamic>> toggleListingFavorite(String id) async {
    return _toggleListingAction(id, 'favorite');
  }

  Future<Map<String, dynamic>> toggleListingInterested(String id) async {
    return _toggleListingAction(id, 'interested');
  }

  Future<Map<String, dynamic>> _toggleListingAction(
    String id,
    String action,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/listings/$id/$action'),
          headers: _jsonHeaders,
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('listing_action_error');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> fetchFavorites() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/me/favorites'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('favorites_error');
    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    List<dynamic> section(String key) =>
        (data[key] as Map<String, dynamic>?)?['data'] as List<dynamic>? ?? [];
    data['providers'] = section('providers')
        .map((item) => _normalizeMedia(Map<String, dynamic>.from(item as Map)))
        .toList();
    data['listings'] = section('listings')
        .map((item) => _normalizeMedia(Map<String, dynamic>.from(item as Map)))
        .toList();
    return data;
  }

  Future<void> renewListing(String id) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/me/listings/$id/renew'),
          headers: _jsonHeaders,
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('renew_error');
  }

  Future<void> deleteListing(String id) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/api/me/listings/$id'),
          headers: _jsonHeaders,
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('delete_listing_error');
  }

  Future<void> submitSupportTicket({
    required String subject,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/support-tickets'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'subject': subject.trim(),
            'message': message.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('support_error');
  }

  Future<void> submitListing({
    required String title,
    required String category,
    required double price,
    required String areaId,
    required List<String> images,
    String? description,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/listings'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'title': title,
            'category': category,
            'price': price,
            'areaId': areaId,
            'images': images,
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('listing_error');
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/me'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('profile_error');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> fetchPublicProfile(String userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/users/$userId'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) throw Exception('profile_error');
    final profile = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    final contributions = profile['contributions'] as Map<String, dynamic>?;
    if (contributions != null) {
      contributions['listings'] =
          (contributions['listings'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    _normalizeMedia(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
      contributions['providers'] =
          (contributions['providers'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    _normalizeMedia(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
    }
    return profile;
  }

  Future<Map<String, dynamic>> fetchContributions() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/me/contributions'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('contributions_error');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> updatePreferences({
    required bool profilePrivate,
    required String notificationScope,
    bool notificationsEnabled = true,
    required bool notificationDigest,
    List<String>? preferredAreaIds,
    List<String>? interests,
    String? ageRange,
    String? gender,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/me/preferences'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'isProfilePrivate': profilePrivate,
            'notificationScope': notificationScope,
            'notificationsEnabled': notificationsEnabled,
            'notificationDigest': notificationDigest,
            if (preferredAreaIds != null)
              'preferredAreaIds': preferredAreaIds.take(3).toList(),
            if (interests != null) 'interests': interests.take(5).toList(),
            'ageRange': ageRange,
            'gender': gender,
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('preferences_error');
  }

  Future<void> logout() async {
    await http
        .post(Uri.parse('$baseUrl/api/auth/logout'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    await AuthSession.clear();
  }

  Future<void> logoutAll() async {
    final response = await http
        .post(Uri.parse('$baseUrl/api/auth/logout-all'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 401) throw Exception('unauthorized');
    await AuthSession.clear();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/me/password'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 400) throw Exception('invalid_password');
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('password_error');
  }

  Future<void> deleteAccount() async {
    final response = await http
        .delete(Uri.parse('$baseUrl/api/me'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('delete_account_error');
    await AuthSession.clear();
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/notifications'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 200) throw Exception('notifications_error');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await http
        .patch(
          Uri.parse('$baseUrl/api/notifications/$id/read'),
          headers: _jsonHeaders,
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<void> markAllNotificationsRead() async {
    await http
        .post(
          Uri.parse('$baseUrl/api/notifications/read-all'),
          headers: _jsonHeaders,
        )
        .timeout(const Duration(seconds: 5));
  }
}
