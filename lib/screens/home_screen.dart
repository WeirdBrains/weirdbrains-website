import 'package:flutter/material.dart';
import '../widgets/hero_section.dart';
import '../widgets/capabilities_section.dart';
import '../widgets/projects_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/cta_section.dart';
import '../widgets/footer_section.dart';
import '../widgets/top_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _projectsKey = GlobalKey();
  final _approachKey = GlobalKey();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final s = _scroll.offset > 40;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeroSection(onSeeWork: () => _goTo(_projectsKey)),
                const CapabilitiesSection(),
                KeyedSubtree(key: _projectsKey, child: const ProjectsSection()),
                KeyedSubtree(
                    key: _approachKey, child: const HowItWorksSection()),
                const CtaSection(),
                const FooterSection(),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopNav(
              scrolled: _scrolled,
              onWork: () => _goTo(_projectsKey),
              onApproach: () => _goTo(_approachKey),
            ),
          ),
        ],
      ),
    );
  }
}
