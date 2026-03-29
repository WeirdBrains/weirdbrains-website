import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const WeirdBrainsApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
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
