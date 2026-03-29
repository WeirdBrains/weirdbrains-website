import 'package:flutter/material.dart';
import '../widgets/hero_section.dart';
import '../widgets/portfolio_section.dart';
import '../widgets/footer_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            HeroSection(),
            PortfolioSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}
