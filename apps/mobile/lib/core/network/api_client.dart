import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../auth/auth_session.dart';

class ProviderSummary {
  const ProviderSummary({required this.id, required this.name, required this.subtitle});
  final String id;
  final String name;
  final String subtitle;
  factory ProviderSummary.fromJson(Map<String, dynamic> json) => ProviderSummary(id: json['id'] as String, name: json['name'] as String, subtitle: '${json['area']?['name'] ?? 'قنا'} · ${json['isVerified'] == true ? 'موثق · ' : ''}مفتوح الآن');
}

class CategoryOption {
  const CategoryOption({required this.id, required this.name});
  final String id;
  final String name;
  factory CategoryOption.fromJson(Map<String, dynamic> json) => CategoryOption(id: json['id'] as String, name: json['name'] as String);
}

class AreaOption {
  const AreaOption({required this.id, required this.name});
  final String id;
  final String name;
  factory AreaOption.fromJson(Map<String, dynamic> json) => AreaOption(id: json['id'] as String, name: json['name'] as String);
}

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:4000');
  final String baseUrl;

  Map<String, String> get _jsonHeaders => {
    'content-type': 'application/json',
    if (AuthSession.isSignedIn) 'authorization': 'Bearer ${AuthSession.token}',
  };

  Future<void> register({required String name, required String phone, required String password, String? email}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/auth/register'), headers: _jsonHeaders, body: jsonEncode({'name': name, 'phone': phone, 'password': password, if (email != null && email.isNotEmpty) 'email': email})).timeout(const Duration(seconds: 8));
    await _saveAuthenticatedSession(response);
  }

  Future<void> login({required String phone, required String password}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/auth/login'), headers: _jsonHeaders, body: jsonEncode({'phone': phone, 'password': password})).timeout(const Duration(seconds: 8));
    await _saveAuthenticatedSession(response);
  }

  Future<void> _saveAuthenticatedSession(http.Response response) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.statusCode == 401 ? 'invalid_credentials' : 'auth_error');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await AuthSession.save(newToken: body['token'] as String, userName: (body['user'] as Map<String, dynamic>)['name'] as String);
  }

  Future<List<CategoryOption>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/categories')).timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) throw Exception('API error ${response.statusCode}');
    return (jsonDecode(response.body) as List<dynamic>).map((item) => CategoryOption.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<AreaOption>> fetchAreas() async {
    final response = await http.get(Uri.parse('$baseUrl/api/areas')).timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) throw Exception('API error ${response.statusCode}');
    return (jsonDecode(response.body) as List<dynamic>).map((item) => AreaOption.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> submitProvider({required Map<String, dynamic> data}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/providers'), headers: _jsonHeaders, body: jsonEncode(data)).timeout(const Duration(seconds: 8));
    if (response.statusCode == 409) throw Exception('duplicate');
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('API error ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> uploadProviderImages(List<XFile> images) async {
    if (!AuthSession.isSignedIn) throw Exception('unauthorized');
    final payload = <Map<String, String>>[];
    for (final image in images) {
      final path = image.path.toLowerCase();
      final mimeType = path.endsWith('.png') ? 'image/png' : path.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
      payload.add({'base64': base64Encode(await image.readAsBytes()), 'mimeType': mimeType});
    }
    final response = await http.post(Uri.parse('$baseUrl/api/uploads/provider-images'), headers: _jsonHeaders, body: jsonEncode({'images': payload})).timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('upload_error');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['images'] as List<dynamic>).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> submitProviderReport({required Map<String, dynamic> data}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/provider-reports'), headers: _jsonHeaders, body: jsonEncode(data)).timeout(const Duration(seconds: 8));
    if (response.statusCode == 401) throw Exception('unauthorized');
    if (response.statusCode != 201) throw Exception('API error ${response.statusCode}');
  }

  Future<List<ProviderSummary>> fetchProviders({String? areaId, String? category}) async {
    final query = <String, String>{
      ...?(areaId == null ? null : {'areaId': areaId}),
      ...?(category == null ? null : {'category': category}),
    };
    final uri = Uri.parse('$baseUrl/api/providers').replace(queryParameters: query);
    final response = await http.get(uri).timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) throw Exception('API error ${response.statusCode}');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => ProviderSummary.fromJson(item as Map<String, dynamic>)).toList();
  }
}
