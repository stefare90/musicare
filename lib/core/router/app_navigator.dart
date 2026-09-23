import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/router/app_routes.dart';

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

  static void pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }
}
