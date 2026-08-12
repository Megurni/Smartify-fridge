part of '../main.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key, required this.foods});

  final List<FoodItem> foods;

  @override
  Widget build(BuildContext context) {
    final urgentNames = foods
        .where((food) => food.priority != FoodPriority.later)
        .map((food) => food.name.toLowerCase())
        .toList();
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(
            title: 'Cook what you have',
            subtitle: 'Recipes ranked to rescue food first',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          sliver: SliverList.list(
            children: [
              _RecipeCard(
                emoji: '🍲',
                title: 'Creamy chicken & spinach',
                subtitle: 'Uses chicken breast + baby spinach',
                time: '25 min',
                match: urgentNames.isEmpty ? 72 : 96,
                missing: '1 item needed',
                featured: true,
              ),
              const SizedBox(height: 14),
              const _RecipeCard(
                emoji: '🍝',
                title: 'Garlic mushroom pasta',
                subtitle: 'Uses mushrooms + Greek yogurt',
                time: '20 min',
                match: 89,
                missing: '2 items needed',
              ),
              const SizedBox(height: 14),
              const _RecipeCard(
                emoji: '🥗',
                title: 'Warm veggie power bowl',
                subtitle: 'Uses spinach + carrots + eggs',
                time: '18 min',
                match: 84,
                missing: 'No shopping needed',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.match,
    required this.missing,
    this.featured = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String time;
  final int match;
  final String missing;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: featured ? const Color(0xFF173F39) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: featured
                      ? const Color(0xFF28655A)
                      : const Color(0xFFFFE9D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 40)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: featured ? Colors.white : null,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: featured
                            ? const Color(0xFFCAE2D5)
                            : Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _RecipeTag(
                icon: Icons.schedule_rounded,
                label: time,
                dark: featured,
              ),
              const SizedBox(width: 8),
              _RecipeTag(
                icon: Icons.shopping_bag_outlined,
                label: missing,
                dark: featured,
              ),
              const Spacer(),
              Text(
                '$match% match',
                style: TextStyle(
                  color: featured
                      ? const Color(0xFFF2B866)
                      : const Color(0xFF28655A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecipeTag extends StatelessWidget {
  const _RecipeTag({
    required this.icon,
    required this.label,
    required this.dark,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: dark ? const Color(0xFFCAE2D5) : Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: dark ? const Color(0xFFCAE2D5) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
