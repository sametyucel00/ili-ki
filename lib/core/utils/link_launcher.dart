import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalLink(String value) async {
  final uri = Uri.parse(value);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
