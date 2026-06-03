import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/start_screen.dart';

void main() {
  // Clean paths (weirdbrains.com/start) instead of hash URLs (/#/start).
  // nginx try_files already serves index.html for any path, so deep links work.
  usePathUrlStrategy();
  runApp(const WeirdBrainsApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
    GoRoute(path: '/start', builder: (ctx, state) => const StartScreen()),
  ],
);

class WeirdBrainsApp extends StatelessWidget {
  const WeirdBrainsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Weird Brains',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
