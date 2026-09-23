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
    final entry = await showDialog<({String name, String quantity})>(
      context: context,
      builder: (_) => const _AddFoodDialog(),
    );
    if (entry == null || !mounted) return;
    final name = entry.name;
    final quantity = entry.quantity;
    final food = FoodItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      emoji: '🥑',
      quantity: quantity.isEmpty ? '1 item' : quantity,
      daysLeft: 7,
      price: 0,
      priority: FoodPriority.later,
      category: 'Other',
    );
    await _changeFoods(
      () => _repository.addFood(food),
      '$name added to your fridge',
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
      RecipesPage(foods: _foods),
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
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add food'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Food name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a food name'
                  : null,
            ),
            TextFormField(
              controller: _quantity,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const Text('For now, new foods use a 7-day estimate and no price.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, (
                name: _name.text.trim(),
                quantity: _quantity.text.trim(),
              ));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
