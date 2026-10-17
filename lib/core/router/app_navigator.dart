import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

abstract class AppNavigator {
  static void toHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  static void toWelcome(BuildContext context) {
    context.go(AppRoutes.welcome);
  }

  static void toSearch(BuildContext context) {
    context.go(AppRoutes.search);
  }

  static void toLibrary(BuildContext context) {
    context.go(AppRoutes.library);
  }

  static void toPlaylistDetail(BuildContext context, Playlist playlist) {
    context.push(AppRoutes.playlist, extra: playlist);
  }

  static void toAlbumDetail(BuildContext context, Album album) {
    context.push(AppRoutes.album, extra: album);
  }

  static void toArtistDetail(BuildContext context, Artist artist) {
    context.push(AppRoutes.artist, extra: artist);
  }

  static void toMediaDetail(BuildContext context, Object item) {
    switch (item) {
      case Playlist p:
        toPlaylistDetail(context, p);
      case Album a:
        toAlbumDetail(context, a);
      case Artist art:
        toArtistDetail(context, art);
      default:
        break;
    }
  }

  static void toLikedTracks(BuildContext context) {
    context.push(AppRoutes.likedTracks);
  }

  static void toDownloads(BuildContext context) {
    context.push(AppRoutes.downloads);
  }

  static void toSettings(BuildContext context) {
    context.push(AppRoutes.settings);
  }

  static void toPluginDetail(BuildContext context, PluginType type) {
    context.push('${AppRoutes.settingsPlugin}/${type.name}');
  }

  static void toAbout(BuildContext context) {
    context.push(AppRoutes.settingsAbout);
  }

  static void pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }
}
