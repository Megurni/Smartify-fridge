part of '../main.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.foods,
    required this.onRemove,
    required this.onEdit,
    this.pendingReviewCount = 0,
    this.onReviewPending,
  });

  final List<FoodItem> foods;
  final void Function(FoodItem food, FoodStatus outcome) onRemove;
  final ValueChanged<FoodItem> onEdit;
  final int pendingReviewCount;
  final VoidCallback? onReviewPending;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  FoodPriority? _filter;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sorted = InventoryPriority.sorted(widget.foods, now);
    final visible = _filter == null
        ? sorted
        : sorted
              .where((food) => InventoryPriority.priority(food, now) == _filter)
              .toList();
    return Column(
      children: [
        const PageHeader(
          title: 'My refrigerator',
          subtitle: 'Sorted by priority score • tap an item for details',
        ),
        if (widget.pendingReviewCount > 0 && widget.onReviewPending != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(
                  '${widget.pendingReviewCount} ${widget.pendingReviewCount == 1 ? 'item' : 'items'} to review',
                ),
                subtitle: const Text('Check details and save your inventory'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onReviewPending,
              ),
            ),
          ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _FilterChip(
                label: 'All ${widget.foods.length}',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              _FilterChip(
                label: 'Use first',
                selected: _filter == FoodPriority.first,
                onTap: () => setState(() => _filter = FoodPriority.first),
              ),
              _FilterChip(
                label: 'Use soon',
                selected: _filter == FoodPriority.soon,
                onTap: () => setState(() => _filter = FoodPriority.soon),
              ),
              _FilterChip(
                label: 'Use later',
                selected: _filter == FoodPriority.later,
                onTap: () => setState(() => _filter = FoodPriority.later),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: _EmptyCard(message: 'No food in this group'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final food = visible[index];
                    return FoodTile(
                      food: food,
                      onTap: () => _showFoodSheet(context, food),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showFoodSheet(BuildContext context, FoodItem food) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(food.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(
              food.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              '${food.quantity} • stored ${food.storedAt.year}-${food.storedAt.month.toString().padLeft(2, '0')}-${food.storedAt.day.toString().padLeft(2, '0')} • \$${food.price.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 5),
            Text(
              'ID: ${food.id} • Status: ${food.status.name} • Category: ${food.category}',
            ),
            Text(
              'Priority score: ${InventoryPriority.score(food, DateTime.now())}/100',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onEdit(food);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onRemove(food, FoodStatus.consumed);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Consumed'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onRemove(food, FoodStatus.discarded);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Discarded'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
