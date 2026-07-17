import 'dart:convert';

import 'package:http/http.dart' as http;

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
    final response = await http.post(Uri.parse('$baseUrl/api/providers'), headers: {'content-type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 5));
    if (response.statusCode == 409) throw Exception('duplicate');
    if (response.statusCode != 201) throw Exception('API error ${response.statusCode}');
  }

  Future<void> submitProviderReport({required Map<String, dynamic> data}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/provider-reports'), headers: {'content-type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 5));
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
