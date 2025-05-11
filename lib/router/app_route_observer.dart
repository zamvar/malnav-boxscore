import 'package:auto_route/auto_route.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


class AppRouteObserver extends AutoRouterObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.data == null) return;

    debugPrint('AppRouteObserver didPush: ${route.data!.name}');

    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setCustomKey('route', route.data!.name);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute == null) return;

    debugPrint('AppRouteObserver didReplace: ${newRoute.data!.name}');

    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setCustomKey('route', newRoute.data!.name);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (previousRoute == null) return;

    debugPrint('AppRouteObserver didRemove: ${previousRoute.data!.name}');

    if (!kIsWeb) {
      FirebaseCrashlytics.instance
          .setCustomKey('route', previousRoute.data!.name);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute == null || previousRoute.data == null) return;

    debugPrint('AppRouteObserver didPop: ${previousRoute.data!.name}');

    if (!kIsWeb) {
      FirebaseCrashlytics.instance
          .setCustomKey('route', previousRoute.data!.name);
    }
  }
}
