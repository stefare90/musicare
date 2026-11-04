import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:music_are/core/config/app_info.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/app_update.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';

class AppUpdateChecker {
  static const String _apiBase = 'https://api.github.com';
  static const String _accept = 'application/vnd.github+json';
  static const String latestReleaseUrl =
      '$_apiBase/repos/${AppInfo.repositoryOwner}/'
      '${AppInfo.repositoryName}/releases/latest';
  static const Duration requestTimeout = Duration(seconds: 15);

  final http.Client _client;

  AppUpdateChecker({http.Client? client}) : _client = client ?? http.Client();

  Future<AppUpdate?> latest(InstalledApp installed) async {
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(latestReleaseUrl),
            headers: {
              'Accept': _accept,
              'User-Agent':
                  '${AppInfo.name}/${installed.versionName} '
                  '(${installed.versionCode})',
            },
          )
          .timeout(requestTimeout);
    } on Exception {
      throw const UpdateCheckFailed();
    }

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw UpdateCheckFailed(statusCode: response.statusCode);
    }

    try {
      final release = jsonDecode(response.body) as Map<String, dynamic>;
      return AppUpdate.fromRelease(
        release,
        installedVersionCode: installed.versionCode,
      );
    } on FormatException {
      return null;
    }
  }
}
