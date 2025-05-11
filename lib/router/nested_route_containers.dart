import 'package:auto_route/auto_route.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:score_board/router/app_route_observer.dart';

@RoutePage()
class ItemContainerPage extends StatelessWidget {
  const ItemContainerPage({super.key});

  // static FirebaseAnalytics? analytics =
  //     kIsWeb == false ? FirebaseAnalytics.instance : null;
  // static FirebaseAnalyticsObserver? analyticsObserver =
  //     kIsWeb == false ? FirebaseAnalyticsObserver(analytics: analytics!) : null;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: AutoRouter(
        inheritNavigatorObservers: false,
        navigatorObservers: () => [
          AppRouteObserver(),
          // if (kIsWeb == false) analyticsObserver!,
        ],
      ),
    );
  }
}

@RoutePage()
class ProfileContainerPage extends StatelessWidget {
  const ProfileContainerPage({super.key});

  // static FirebaseAnalytics? analytics =
  //     kIsWeb == false ? FirebaseAnalytics.instance : null;
  // static FirebaseAnalyticsObserver? analyticsObserver =
  //     kIsWeb == false ? FirebaseAnalyticsObserver(analytics: analytics!) : null;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: AutoRouter(
        inheritNavigatorObservers: false,
        navigatorObservers: () => [
          AppRouteObserver(),
          // if (kIsWeb == false) analyticsObserver!,
        ],
      ),
    );
  }
}
