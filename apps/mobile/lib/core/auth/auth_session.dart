import 'package:shared_preferences/shared_preferences.dart';

/// جلسة الجهاز فقط: يحتفظ التطبيق بالتوكن، ولا يرسل هوية المستخدم يدوياً.
class AuthSession {
  static const _tokenKey = 'auth_token';
  static const _nameKey = 'auth_name';

  static String? token;
  static String? name;

  static bool get isSignedIn => token != null && token!.isNotEmpty;

  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    token = preferences.getString(_tokenKey);
    name = preferences.getString(_nameKey);
  }

  static Future<void> save({required String newToken, required String userName}) async {
    token = newToken;
    name = userName;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, newToken);
    await preferences.setString(_nameKey, userName);
  }

  static Future<void> clear() async {
    token = null;
    name = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_nameKey);
  }
}
