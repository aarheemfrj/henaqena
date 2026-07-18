import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppActions {
  static String _egyptianInternational(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('20')) return digits;
    if (digits.startsWith('0')) return '20${digits.substring(1)}';
    return digits;
  }

  static Future<bool> call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return false;
    return launchUrl(Uri(scheme: 'tel', path: phone.trim()));
  }

  static Future<bool> whatsapp(String? phone, {String? message}) async {
    if (phone == null || phone.trim().isEmpty) return false;
    final uri = Uri.https('wa.me', '/${_egyptianInternational(phone)}', {
      if (message != null && message.trim().isNotEmpty) 'text': message.trim(),
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> map({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final query = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : address?.trim();
    if (query == null || query.isEmpty) return false;
    final uri = Uri.https('maps.apple.com', '/', {'q': query});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openUrl(String? value) async {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> share(
    BuildContext context, {
    required String text,
    String? subject,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  static Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException('location_permission_denied');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }
}
