part of '../main.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(
            title: 'Your impact',
            subtitle: 'August 2026 waste summary',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          sliver: SliverList.list(
            children: const [
              _SavingsHero(),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.check_circle_outline,
                      value: '24',
                      label: 'Items consumed',
                      color: Color(0xFF28655A),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.delete_outline,
                      value: '3',
                      label: 'Items discarded',
                      color: Color(0xFFD87C4A),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _SectionTitle(title: 'Waste trend'),
              SizedBox(height: 12),
              _WasteChart(),
              SizedBox(height: 24),
              _InsightBanner(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SavingsHero extends StatelessWidget {
  const _SavingsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF28655A), Color(0xFF173F39)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          Text(
            'ESTIMATED SAVINGS',
            style: TextStyle(
              color: Color(0xFFCAE2D5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            r'$37.20',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 42,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '↑ 18% less waste than last month',
            style: TextStyle(
              color: Color(0xFFF2B866),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteChart extends StatelessWidget {
  const _WasteChart();

  @override
  Widget build(BuildContext context) {
    const values = [0.85, 0.68, 0.74, 0.52, 0.43, 0.34];
    const months = ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: SizedBox(
          height: 175,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              values.length,
              (index) => Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 22,
                      height: 112 * values[index],
                      decoration: BoxDecoration(
                        color: index == values.length - 1
                            ? const Color(0xFF28655A)
                            : const Color(0xFFB9D4C9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      months[index],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9D6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFFD87C4A),
            size: 30,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'You rescue produce most often. Keep checking leafy greens first!',
              style: TextStyle(
                color: Color(0xFF6F4C37),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
