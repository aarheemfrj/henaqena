import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../auth/auth_session.dart';

class ProviderSummary {
  const ProviderSummary({
    required this.id,
    required this.name,
    required this.subtitle,
    this.description,
    this.imageUrl,
  });
  final String id;
  final String name;
  final String subtitle;
  final String? description;
  final String? imageUrl;
  factory ProviderSummary.fromJson(
    Map<String, dynamic> json,
  ) => ProviderSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    imageUrl: (json['images'] as List<dynamic>?)?.isNotEmpty == true
        ? ((json['images'] as List<dynamic>).first
                  as Map<String, dynamic>)['url']
              as String?
        : null,
    subtitle:
        '${json['area']?['name'] ?? 'قنا'} · ${json['isVerified'] == true ? 'موثق · ' : ''}مفتوح الآن',
  );
}

class ProviderDetails {
  const ProviderDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.reviews,
  });
  final String id;
  final String name;
  final String? description;
  final List<String> images;
  final List<Map<String, dynamic>> reviews;
  factory ProviderDetails.fromJson(Map<String, dynamic> json) =>
      ProviderDetails(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        images: (json['images'] as List<dynamic>? ?? [])
            .map((item) => (item as Map<String, dynamic>)['url'] as String)
            .toList(),
        reviews: (json['reviews'] as List<dynamic>? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
      );
}

class CategoryOption {
  const CategoryOption({required this.id, required this.name});
  final String id;
  final String name;
  factory CategoryOption.fromJson(Map<String, dynamic> json) =>
      CategoryOption(id: json['id'] as String, name: json['name'] as String);
}

class AreaOption {
  const AreaOption({required this.id, required this.name});
  final String id;
  final String name;
  factory AreaOption.fromJson(Map<String, dynamic> json) =>
      AreaOption(id: json['id'] as String, name: json['name'] as String);
}

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://127.0.0.1:4000',
          );
  final String baseUrl;

  Future<List<Map<String, dynamic>>> fetchAds({String? areaId}) async {
    final uri = Uri.parse(
      '$baseUrl/api/ads',
    ).replace(queryParameters: {if (areaId != null) 'areaId': areaId});
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200)
      throw Exception('API error ${response.statusCode}');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchPrices({String? areaId}) async {
    final uri = Uri.parse(
      '$baseUrl/api/prices',
    ).replace(queryParameters: {if (areaId != null) 'areaId': areaId});
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200)
      throw Exception('API error ${response.statusCode}');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchNow({String? areaId}) async {
    final uri = Uri.parse(
      '$baseUrl/api/now',
    ).replace(queryParameters: {if (areaId != null) 'areaId': areaId});
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200)
      throw Exception('API error ${response.statusCode}');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
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
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/admin/providers/$id'),
          headers: _adminHeaders,
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_moderation_error');
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
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/admin/listings/$id'),
          headers: _adminHeaders,
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('admin_moderation_error');
  }

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

  Future<void> login({required String phone, required String password}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: _jsonHeaders,
          body: jsonEncode({'phone': phone, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));
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
  }

  Future<List<CategoryOption>> fetchCategories() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/categories'))
        .timeout(const Duration(seconds: 3));
    if (response.statusCode != 200)
      throw Exception('API error ${response.statusCode}');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => CategoryOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AreaOption>> fetchAreas() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/areas'))
        .timeout(const Duration(seconds: 3));
    if (response.statusCode != 200)
      throw Exception('API error ${response.statusCode}');
    return (jsonDecode(response.body) as List<dynamic>)
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
    if (response.statusCode != 201)
      throw Exception('API error ${response.statusCode}');
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
    if (response.statusCode != 201)
      throw Exception('API error ${response.statusCode}');
  }

  Future<List<ProviderSummary>> fetchProviders({
    String? areaId,
    String? category,
    String? searchQuery,
    int page = 1,
  }) async {
    final params = <String, String>{
      ...?(areaId == null ? null : {'areaId': areaId}),
      ...?(category == null ? null : {'category': category}),
      ...?(searchQuery == null || searchQuery.trim().isEmpty
          ? null
          : {'q': searchQuery.trim()}),
      'page': '$page',
    };
    final uri = Uri.parse(
      '$baseUrl/api/providers',
    ).replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 3));
    if (response.statusCode != 200)
      throw Exception('API error ${response.statusCode}');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ProviderSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProviderDetails> fetchProvider(String id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/providers/$id'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200)
      throw Exception('API error ${response.statusCode}');
    return ProviderDetails.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
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

  Future<void> submitListing({
    required String title,
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

  Future<void> updatePreferences({
    required bool profilePrivate,
    required String notificationScope,
    required bool notificationDigest,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/me/preferences'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'isProfilePrivate': profilePrivate,
            'notificationScope': notificationScope,
            'notificationDigest': notificationDigest,
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
