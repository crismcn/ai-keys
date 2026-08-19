import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/activation/activation_detail_page.dart';
import '../../features/home/home_page.dart';
import '../../features/import_email/import_email_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: HomePage.route,
  routes: [
    GoRoute(
      path: HomePage.route,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: ImportEmailPage.route,
      name: 'import',
      builder: (context, state) => const ImportEmailPage(),
    ),
    GoRoute(
      path: ActivationDetailPage.route,
      name: 'activation',
      builder: (context, state) => ActivationDetailPage(
        email: state.pathParameters['email']!,
      ),
    ),
  ],
);
