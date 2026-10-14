part of '../main.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, required this.foods});

  final List<FoodItem> foods;

  @override
  Widget build(BuildContext context) {
    final consumed = foods
        .where((food) => food.status == FoodStatus.consumed)
        .toList();
    final discarded = foods
        .where((food) => food.status == FoodStatus.discarded)
        .toList();
    final saved = consumed.fold<double>(0, (total, food) => total + food.price);
    final wasted = discarded.fold<double>(
      0,
      (total, food) => total + food.price,
    );

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(
            title: 'Food accounting',
            subtitle: 'Totals from recorded food outcomes',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          sliver: SliverList.list(
            children: [
              _AccountingHero(saved: saved, wasted: wasted),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.check_circle_outline,
                      value: '${consumed.length}',
                      label: 'Items consumed',
                      color: const Color(0xFF28655A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.delete_outline,
                      value: '${discarded.length}',
                      label: 'Items discarded',
                      color: const Color(0xFFD87C4A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Consumed food counts as saved from waste. Discarded food counts as wasted. Values use each food’s recorded price.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountingHero extends StatelessWidget {
  const _AccountingHero({required this.saved, required this.wasted});

  final double saved;
  final double wasted;

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
      child: Column(
        children: [
          const Text(
            'SAVED FROM WASTE',
            style: TextStyle(
              color: Color(0xFFCAE2D5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${saved.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 42,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wasted: \$${wasted.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFF2B866),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
