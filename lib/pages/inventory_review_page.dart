part of '../main.dart';

class ReviewFoodEdit {
  const ReviewFoodEdit({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  final String id;
  final String name;
  final double price;
  final String category;
}

class InventoryReviewPage extends StatefulWidget {
  const InventoryReviewPage({
    super.key,
    required this.foods,
    required this.onConfirm,
    this.isEditing = false,
  });

  final List<FoodItem> foods;
  final bool isEditing;
  final Future<void> Function(List<ReviewFoodEdit>) onConfirm;

  @override
  State<InventoryReviewPage> createState() => _InventoryReviewPageState();
}

class _InventoryReviewPageState extends State<InventoryReviewPage> {
  static const _categories = [
    'Meat',
    'Seafood',
    'Dairy',
    'Eggs',
    'Fruit',
    'Vegetable',
    'Bakery',
    'Leftovers',
    'Beverage',
    'Condiment',
    'Other',
  ];

  final _form = GlobalKey<FormState>();
  late final List<_ReviewDraft> _drafts = widget.foods
      .map((food) => _ReviewDraft(food))
      .toList();
  bool _saving = false;

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onConfirm([
        for (final draft in _drafts)
          ReviewFoodEdit(
            id: draft.food.id,
            name: draft.name.text.trim(),
            price: double.parse(draft.price.text.trim()),
            category: draft.category,
          ),
      ]);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save inventory. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.isEditing ? 'Edit food' : 'Review new food'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            widget.isEditing
                ? 'Update the details and save your changes.'
                : '${widget.foods.length} new ${widget.foods.length == 1 ? 'item' : 'items'} found in the fridge. Check the details before saving.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final draft in _drafts)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item #${draft.food.id}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: draft.name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: draft.category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) draft.category = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: draft.price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        final price = double.tryParse(value?.trim() ?? '');
                        return price == null || !price.isFinite || price < 0
                            ? 'Enter a valid price'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            TextButton(
              onPressed: _saving
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(widget.isEditing ? 'Cancel' : 'Review later'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving
                    ? 'Saving…'
                    : widget.isEditing
                    ? 'Save changes'
                    : 'Save inventory',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReviewDraft {
  _ReviewDraft(this.food)
    : name = TextEditingController(text: food.name),
      price = TextEditingController(text: food.price.toStringAsFixed(2)),
      category = _InventoryReviewPageState._categories.contains(food.category)
          ? food.category
          : 'Other';

  final FoodItem food;
  final TextEditingController name;
  final TextEditingController price;
  String category;

  void dispose() {
    name.dispose();
    price.dispose();
  }
}
