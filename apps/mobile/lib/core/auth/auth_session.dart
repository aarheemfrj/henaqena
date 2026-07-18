import 'package:shared_preferences/shared_preferences.dart';

/// جلسة الجهاز فقط: يحتفظ التطبيق بالتوكن، ولا يرسل هوية المستخدم يدوياً.
class AuthSession {
  static const _tokenKey = 'auth_token';
  static const _nameKey = 'auth_name';
  static const _adminTokenKey = 'admin_token';
  static const _adminNameKey = 'admin_name';
  static const _adminRoleKey = 'admin_role';

  static String? token;
  static String? name;
  static String? adminToken;
  static String? adminName;
  static String? adminRole;

  static bool get isSignedIn => token != null && token!.isNotEmpty;

  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    token = preferences.getString(_tokenKey);
    name = preferences.getString(_nameKey);
    adminToken = preferences.getString(_adminTokenKey);
    adminName = preferences.getString(_adminNameKey);
    adminRole = preferences.getString(_adminRoleKey);
  }

  static Future<void> save({
    required String newToken,
    required String userName,
  }) async {
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

  static Future<void> updateName(String userName) async {
    name = userName;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nameKey, userName);
  }

  static Future<void> saveAdmin({
    required String newToken,
    required String userName,
    required String role,
  }) async {
    adminToken = newToken;
    adminName = userName;
    adminRole = role;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_adminTokenKey, newToken);
    await preferences.setString(_adminNameKey, userName);
    await preferences.setString(_adminRoleKey, role);
  }

  static Future<void> clearAdmin() async {
    adminToken = null;
    adminName = null;
    adminRole = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_adminTokenKey);
    await preferences.remove(_adminNameKey);
    await preferences.remove(_adminRoleKey);
  }
}
