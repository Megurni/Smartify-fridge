part of '../main.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key, required this.foods, required this.plan,
    required this.onChanged, required this.onUsed, this.busy = false});

  final List<FoodItem> foods;
  final ShoppingPlan plan;
  final VoidCallback onChanged;
  final ValueChanged<FoodItem> onUsed;
  final bool busy;

  Future<void> _edit(BuildContext context, [ShoppingItem? item]) async {
    final result = await showDialog<({String name, String quantity})>(
      context: context,
      builder: (_) => _ShoppingItemDialog(item: item),
    );
    if (result == null) return;
    if (item == null) {
      plan.items.add(ShoppingItem(name: result.name, quantity: result.quantity));
    } else {
      item.name = result.name;
      item.quantity = result.quantity;
      item.purchased = false;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final stock = InventoryPriority.sorted(foods, DateTime.now());
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const PageHeader(title: 'Savings & Shopping List',
          subtitle: 'Plan your meals. Make the most of your fridge.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Money saved', style: TextStyle(fontSize: 18)),
                    Text('\$${plan.savings(foods).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold,
                        color: Color(0xFF28655A))),
                    const Text('Recorded value of fridge food marked used before its '
                      'estimated expiry. Purchases do not add savings.'),
                    const SizedBox(height: 8),
                    const Text('Data lasts for this app session.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              const Text('Planned recipes',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              if (plan.recipes.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Choose Want to Make on the Recipes page.')),
              for (final recipe in plan.recipes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(recipe.name),
                  subtitle: const Text('Tap to view ingredients and instructions'),
                  onTap: () => showDialog<void>(context: context,
                    builder: (_) => _RecipeDetails(match: RecipeMatch(recipe, stock))),
                  trailing: IconButton(
                    tooltip: 'Remove planned recipe',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      plan.recipes.remove(recipe);
                      onChanged();
                    },
                  ),
                ),
              const Text('Removing a plan keeps your edited shopping items. '
                'Remove any unwanted items below.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Text('Shopping list',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
                TextButton.icon(onPressed: () => _edit(context),
                  icon: const Icon(Icons.add), label: const Text('Add item')),
              ]),
              const Text('Match by ingredient name; check quantities. '
                'Use the pencil to change or replace an ingredient.'),
              if (plan.items.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Your shopping list is empty.')),
              for (final item in plan.items)
                Card(margin: const EdgeInsets.only(top: 8), child: Row(children: [
                  Checkbox(value: item.purchased, onChanged: (value) {
                    item.purchased = value ?? false;
                    onChanged();
                  }),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: TextStyle(fontWeight: FontWeight.w600,
                          decoration: item.purchased ? TextDecoration.lineThrough : null)),
                        if (item.quantity.isNotEmpty) Text(item.quantity),
                        if (item.recipeName != null) Text(item.recipeName!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )),
                  IconButton(tooltip: 'Edit ${item.name}',
                    onPressed: () => _edit(context, item), icon: const Icon(Icons.edit_outlined)),
                  IconButton(tooltip: 'Remove ${item.name}', onPressed: () {
                    plan.items.remove(item);
                    onChanged();
                  }, icon: const Icon(Icons.delete_outline)),
                ])),
              const SizedBox(height: 24),
              const Text('Used food from your fridge?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const Text('Mark used only after cooking. This uses the full recorded '
                'quantity and removes it from inventory. You can undo the action.'),
              if (stock.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No ingredients left in your fridge.')),
              for (final food in stock)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(food.name),
                  subtitle: Text('${food.quantity} · \$${food.price.toStringAsFixed(2)}'
                    '${food.daysLeft <= 0 ? '\nPast estimated shelf life: no savings credit' : ''}'),
                  trailing: TextButton(
                    onPressed: busy ? null : () => onUsed(food),
                    child: const Text('Mark used'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShoppingItemDialog extends StatefulWidget {
  const _ShoppingItemDialog({this.item});
  final ShoppingItem? item;

  @override
  State<_ShoppingItemDialog> createState() => _ShoppingItemDialogState();
}

class _ShoppingItemDialogState extends State<_ShoppingItemDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _quantity = TextEditingController(text: widget.item?.quantity ?? '');

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Add shopping item' : 'Edit shopping item'),
    content: SingleChildScrollView(child: Form(key: _form, child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(controller: _name, autofocus: true,
          decoration: const InputDecoration(labelText: 'Ingredient'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter an ingredient' : null),
        TextFormField(controller: _quantity,
          decoration: const InputDecoration(labelText: 'Quantity / notes')),
      ],
    ))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () {
        if (_form.currentState!.validate()) {
          Navigator.pop(context, (name: _name.text.trim(), quantity: _quantity.text.trim()));
        }
      }, child: const Text('Save')),
    ],
  );
}
