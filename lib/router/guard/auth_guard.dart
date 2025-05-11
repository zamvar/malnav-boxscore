// import 'package:auto_route/auto_route.dart';
// import 'package:flutter/material.dart';

// // import '../app_router.gr.dart';
// // import 'package:isangguni/services/secure_storage.dart';

// class AuthGuard extends AutoRouteGuard {
//   // final storage = SecureStorage();

//   @override
//   Future<void> onNavigation(
//     NavigationResolver resolver,
//     StackRouter router,
//   ) async {
//     // final loggedIn =
//     //     await storage.read(key: constCurrentUser) == null ? false : true;
//     // debugPrint('AuthGuard loggedIn: $loggedIn');
//     // if (loggedIn == true) {
//     //   debugPrint('AuthGuard user is logged in');
//     //   resolver.next(true);
//     // } else {
//     //   debugPrint('AuthGuard User is not logged in');
//     //   resolver.redirect(
//     //     LoginRoute(
//     //       onResult: (success) {
//     //         // if success == true the navigation will be resumed
//     //         // else it will be aborted
//     //         resolver.next(success);
//     //       },
//     //     ),
//     //   );
//     // }
//     resolver.next(true);
//   }
// }
