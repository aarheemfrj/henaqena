import 'dart:convert';

import 'package:http/http.dart' as http;

class ProviderSummary {
  const ProviderSummary({required this.id, required this.name, required this.subtitle});
  final String id;
  final String name;
  final String subtitle;
  factory ProviderSummary.fromJson(Map<String, dynamic> json) => ProviderSummary(id: json['id'] as String, name: json['name'] as String, subtitle: '${json['area']?['name'] ?? 'قنا'} · ${json['isVerified'] == true ? 'موثق · ' : ''}مفتوح الآن');
}

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:4000');
  final String baseUrl;

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
