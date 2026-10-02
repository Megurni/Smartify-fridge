part of 'main.dart';

class SmartifyApp extends StatelessWidget {
  const SmartifyApp({super.key, this.foodRepository});

  final FoodRepository? foodRepository;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF28655A);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smartify Refrigerator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFF7F8F3),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F3),
        fontFamily: 'sans-serif',
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
      ),
      home: SmartifyShell(foodRepository: foodRepository),
    );
  }
}

class SmartifyShell extends StatefulWidget {
  const SmartifyShell({super.key, this.foodRepository});

  final FoodRepository? foodRepository;

  @override
  State<SmartifyShell> createState() => _SmartifyShellState();
}

class _SmartifyShellState extends State<SmartifyShell> {
  int _selectedIndex = 0;
  late final FoodRepository _repository;
  List<FoodItem> _foods = [];
  bool _loading = true;
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repository = widget.foodRepository ?? InMemoryFoodRepository();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final foods = await _repository.getFoods();
      if (mounted) setState(() => _foods = foods);
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Could not load foods. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeFoods(
    Future<void> Function() change,
    String message, {
    VoidCallback? undo,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await change();
      if (!mounted) return;
      await _loadFoods();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: undo == null
                ? null
                : SnackBarAction(label: 'UNDO', onPressed: undo),
          ),
        );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the change. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _removeFood(FoodItem food, String outcome) {
    _changeFoods(
      () => _repository.deleteFood(food.id),
      '${food.name} marked as $outcome',
      undo: () => _changeFoods(
        () => _repository.addFood(food),
        '${food.name} restored',
      ),
    );
  }

  Future<void> _addFood() async {
    final entry =
        await showDialog<
          ({String name, String quantity, double price, int daysLeft})
        >(context: context, builder: (_) => const _AddFoodDialog());

    if (entry == null || !mounted) return;

    final priority = entry.daysLeft <= 2
        ? FoodPriority.first
        : entry.daysLeft <= 5
        ? FoodPriority.soon
        : FoodPriority.later;

    final food = FoodItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: entry.name,
      emoji: '🥑',
      quantity: entry.quantity,
      daysLeft: entry.daysLeft,
      price: entry.price,
      priority: priority,
      category: 'Other',
    );

    await _changeFoods(
      () => _repository.addFood(food),
      '${entry.name} added to your fridge',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        foods: _foods,
        onViewInventory: () => setState(() => _selectedIndex = 1),
        onViewRecipes: () => setState(() => _selectedIndex = 2),
      ),
      InventoryPage(foods: _foods, onRemove: _removeFood),
      RecipesPage(foods: _foods, active: _selectedIndex == 2),
      const InsightsPage(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!),
                    TextButton(
                      onPressed: _loadFoods,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : IndexedStack(index: _selectedIndex, children: pages),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _busy || _loading || _loadError != null
                  ? null
                  : _addFood,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add food'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen_rounded),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Savings',
          ),
        ],
      ),
    );
  }
}

class _AddFoodDialog extends StatefulWidget {
  const _AddFoodDialog();

  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1 item');
  final _price = TextEditingController(text: '0.00');
  final _daysLeft = TextEditingController(text: '7');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    _daysLeft.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, (
      name: _name.text.trim(),
      quantity: _quantity.text.trim(),
      price: double.parse(_price.text.trim()),
      daysLeft: int.parse(_daysLeft.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add food'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Food name',
                    hintText: 'e.g. Tomatoes',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a food name';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantity,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g. 3 pieces or 500 g',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a quantity';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Total price',
                    prefixText: '\$ ',
                    helperText: 'Price for the entire quantity entered above.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final price = double.tryParse(text);

                    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text) ||
                        price == null ||
                        !price.isFinite ||
                        price < 0) {
                      return 'Enter a valid price, such as 4.50';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _daysLeft,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Days remaining',
                    hintText: 'e.g. 3',
                    helperText: 'Enter 0 if it should be used today.',
                  ),
                  validator: (value) {
                    final days = int.tryParse(value?.trim() ?? '');

                    if (days == null || days < 0) {
                      return 'Enter a whole number of 0 or more';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  '0–2 days: Use First\n'
                  '3–5 days: Use Soon\n'
                  '6+ days: Use Later',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF58645C),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
