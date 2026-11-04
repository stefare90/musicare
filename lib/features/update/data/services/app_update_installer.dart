import 'dart:io';

import 'package:flutter/services.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/apk_info.dart';
import 'package:music_are/features/update/data/services/app_update_channel.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';

class AppUpdateInstaller {
  static const MethodChannel channel = MethodChannel('com.musicare.app_update');

  final MethodChannel _channel;

  AppUpdateInstaller({MethodChannel? channel})
    : _channel = channel ?? AppUpdateInstaller.channel;

  Future<String> updatesDir() async {
    final path = await _invoke<String>(AppUpdateChannel.updatesDir);
    if (path == null || path.isEmpty) throw const UpdateInstallFailed();
    return path;
  }

  Future<String> installedSignature() async {
    final signature = await _invoke<String>(AppUpdateChannel.signature);
    if (signature == null || signature.isEmpty) {
      throw const UpdateInstallFailed();
    }
    return signature.toLowerCase();
  }

  Future<ApkInfo> apkInfo(String path) async {
    final info = ApkInfo.fromMethodResult(
      await _invoke<Map<Object?, Object?>>(AppUpdateChannel.apkInfo, {
        'path': path,
      }),
    );
    if (info == null) throw const UpdateRejected();
    return info;
  }

  Future<void> install({
    required String apkPath,
    required InstalledApp installed,
    required int expectedVersionCode,
  }) async {
    final info = await apkInfo(apkPath);
    final installedCert = await installedSignature();
    if (info.packageName != installed.packageName ||
        info.versionCode != expectedVersionCode ||
        info.certSha256 != installedCert) {
      await _deleteQuietly(apkPath);
      throw const UpdateRejected();
    }
    await _invoke<void>(AppUpdateChannel.install, {'path': apkPath});
  }

  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      throw const UpdateInstallFailed();
    } on MissingPluginException {
      throw const UpdateInstallFailed();
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort: the gate already refused the package.
    }
  }
}
