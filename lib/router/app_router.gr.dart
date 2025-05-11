// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i6;
import 'package:flutter/material.dart' as _i7;
import 'package:score_board/app/features/dashboard/view/dashboard.dart' as _i1;
import 'package:score_board/app/features/game/view/game.dart' as _i5;
import 'package:score_board/app/features/lobby/view/lobby.dart' as _i2;
import 'package:score_board/app/features/login/view/login.dart' as _i4;
import 'package:score_board/router/nested_route_containers.dart' as _i3;

/// generated route for
/// [_i1.DashboardRoute]
class DashboardRoute extends _i6.PageRouteInfo<void> {
  const DashboardRoute({List<_i6.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i1.DashboardRoute();
    },
  );
}

/// generated route for
/// [_i2.GameLobbyRoute]
class GameLobbyRoute extends _i6.PageRouteInfo<void> {
  const GameLobbyRoute({List<_i6.PageRouteInfo>? children})
    : super(GameLobbyRoute.name, initialChildren: children);

  static const String name = 'GameLobbyRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i2.GameLobbyRoute();
    },
  );
}

/// generated route for
/// [_i3.ItemContainerPage]
class ItemContainerRoute extends _i6.PageRouteInfo<void> {
  const ItemContainerRoute({List<_i6.PageRouteInfo>? children})
    : super(ItemContainerRoute.name, initialChildren: children);

  static const String name = 'ItemContainerRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i3.ItemContainerPage();
    },
  );
}

/// generated route for
/// [_i4.LoginRoute]
class LoginRoute extends _i6.PageRouteInfo<void> {
  const LoginRoute({List<_i6.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i4.LoginRoute();
    },
  );
}

/// generated route for
/// [_i3.ProfileContainerPage]
class ProfileContainerRoute extends _i6.PageRouteInfo<void> {
  const ProfileContainerRoute({List<_i6.PageRouteInfo>? children})
    : super(ProfileContainerRoute.name, initialChildren: children);

  static const String name = 'ProfileContainerRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i3.ProfileContainerPage();
    },
  );
}

/// generated route for
/// [_i5.ScoreboardGameRoute]
class ScoreboardGameRoute extends _i6.PageRouteInfo<ScoreboardGameRouteArgs> {
  ScoreboardGameRoute({
    required String gameId,
    _i7.Key? key,
    List<_i6.PageRouteInfo>? children,
  }) : super(
         ScoreboardGameRoute.name,
         args: ScoreboardGameRouteArgs(gameId: gameId, key: key),
         rawPathParams: {'gameId': gameId},
         initialChildren: children,
       );

  static const String name = 'ScoreboardGameRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ScoreboardGameRouteArgs>(
        orElse:
            () =>
                ScoreboardGameRouteArgs(gameId: pathParams.getString('gameId')),
      );
      return _i5.ScoreboardGameRoute(gameId: args.gameId, key: args.key);
    },
  );
}

class ScoreboardGameRouteArgs {
  const ScoreboardGameRouteArgs({required this.gameId, this.key});

  final String gameId;

  final _i7.Key? key;

  @override
  String toString() {
    return 'ScoreboardGameRouteArgs{gameId: $gameId, key: $key}';
  }
}
