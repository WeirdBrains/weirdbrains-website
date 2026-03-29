import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PortfolioItem {
  final String name;
  final String tagline;
  final String status;
  final String url;

  const PortfolioItem({
    required this.name,
    required this.tagline,
    required this.status,
    required this.url,
  });
}

const _portfolio = [
  PortfolioItem(
    name: 'Mandible',
    tagline: 'AI-powered dental case platform for specialists.',
    status: 'Launching 2026',
    url: 'https://mandible.ai',
  ),
  PortfolioItem(
    name: 'WickHackers',
    tagline: 'Algorithmic trading: Coinbase perps, Kalshi, prediction markets.',
    status: 'Active',
    url: '',
  ),
  PortfolioItem(
    name: 'Myelin / GYRI',
    tagline: 'Rust L1 blockchain with usage-adaptive tokenomics.',
    status: 'In development',
    url: '',
  ),
];

class PortfolioSection extends StatelessWidget {
  const PortfolioSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 96),
      child: Column(
        children: [
          Text(
            'Portfolio',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 64),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: _portfolio.map((item) => _PortfolioCard(item: item)).toList(),
          ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  const _PortfolioCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            )),
          const SizedBox(height: 12),
          Text(item.tagline,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(item.status,
              style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
