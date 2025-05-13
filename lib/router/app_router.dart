import 'package:auto_route/auto_route.dart';
import 'package:score_board/app/features/login/auth_guard.dart';

import 'package:score_board/router/app_router.gr.dart';

// see tutorial: https://www.youtube.com/watch?v=GINXiO5Te4U
// generate routes: dart run build_runner build -d
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: LoginRoute.page,
          initial: true,
          guards: const [],
        ),
        AutoRoute(
          path: '/dashboard',
          page: DashboardRoute.page,
          initial: false,
          guards: [AuthGuard()],
        ),
        AutoRoute(
          path: '/lobby',
          page: GameLobbyRoute.page,
          initial: false,
          guards: [AuthGuard()],
        ),
        AutoRoute(
          path:
              '/gamelog/:gameId', // UPDATED: Added :gameId as a path parameter
          page: ScoreboardGameRoute.page,
          initial: false,
          guards: [AuthGuard()],
        ),
        // AutoRoute(
        //   path: '/home',
        //   page: HomeRoute.page,
        // guards: [AuthGuard()],
        // children: [
        //   AutoRoute(
        //     path: 'item_list',
        //     page: ItemListRoute.page,
        //     initial: true,
        //   ),
        //   AutoRoute(
        //     path: 'item',
        //     page: ItemContainerPage.page,
        //     children: [
        //       AutoRoute(
        //         path: 'details',
        //         page: ItemDetailsRoute.page,
        //         initial: true,
        //       ),
        //     ],
        //   ),
        // ],
        // ),
        // AutoRoute(
        //   path: '/settings',
        //   page: SettingsRoute.page,
        //   guards: [AuthGuard()],
        //   children: [
        //     AutoRoute(
        //       path: 'profile/view',
        //       page: ProfileRoute.page,
        //       initial: true,
        //     ),
        //     AutoRoute(
        //       path: 'profile',
        //       page: ProfileContainerRoute.page,
        //       children: [
        //         AutoRoute(
        //           path: 'edit',
        //           page: EditProfile.page,
        //           initial: true,
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
      ];
}
