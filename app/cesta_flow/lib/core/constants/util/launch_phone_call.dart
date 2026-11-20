import 'package:url_launcher/url_launcher.dart';

String phoneDigitsForDial(String phone) =>
    phone.replaceAll(RegExp(r'[^0-9+]'), '');

Future<bool> launchPhoneCall(String phone) async {
  final digits = phoneDigitsForDial(phone);
  if (digits.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: digits);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}