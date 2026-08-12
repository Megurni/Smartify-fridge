part of '../main.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.foods,
    required this.onViewInventory,
    required this.onViewRecipes,
  });

  final List<FoodItem> foods;
  final VoidCallback onViewInventory;
  final VoidCallback onViewRecipes;

  @override
  Widget build(BuildContext context) {
    final urgent = foods
        .where((food) => food.priority == FoodPriority.first)
        .toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Good morning 👋',
            subtitle: '${foods.length} items in your refrigerator',
            trailing: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(
            children: [
              _HeroCard(urgentCount: urgent.length, onTap: onViewInventory),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'Use first', action: 'See inventory'),
              const SizedBox(height: 12),
              if (urgent.isEmpty)
                const _EmptyCard(message: 'Nothing urgent — great job!')
              else
                ...urgent
                    .take(2)
                    .map(
                      (food) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FoodTile(food: food),
                      ),
                    ),
              const SizedBox(height: 12),
              _RecipeSpotlight(onTap: onViewRecipes),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'This month'),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.savings_outlined,
                      value: r'$37',
                      label: 'Waste avoided',
                      color: Color(0xFF28655A),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.eco_outlined,
                      value: '18%',
                      label: 'Less waste',
                      color: Color(0xFFD87C4A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.urgentCount, required this.onTap});

  final int urgentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF173F39),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F173F39),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAVE IT BEFORE\nYOU WASTE IT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    height: 1.08,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  urgentCount == 0
                      ? 'Your fridge is all under control.'
                      : '$urgentCount items need your attention today.',
                  style: const TextStyle(
                    color: Color(0xFFCAE2D5),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.tonal(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF2B866),
                    foregroundColor: const Color(0xFF173F39),
                  ),
                  child: const Text('Check now'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 100,
            height: 130,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF28655A),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text('🥬', style: TextStyle(fontSize: 58)),
          ),
        ],
      ),
    );
  }
}

class _RecipeSpotlight extends StatelessWidget {
  const _RecipeSpotlight({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9D6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Text('🍲', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tonight’s rescue recipe',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(height: 5),
                Text(
                  'Creamy chicken & spinach',
                  style: TextStyle(color: Color(0xFF77543D)),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}
