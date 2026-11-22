part of 'main.dart';

class SmartifyApp extends StatelessWidget {
  const SmartifyApp({
    super.key,
    this.foodRepository,
    this.inventoryReviewStore,
    this.shoppingPlanStore,
  });

  final FoodRepository? foodRepository;
  final InventoryReviewStore? inventoryReviewStore;
  final ShoppingPlanStore? shoppingPlanStore;

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
      home: SmartifyShell(
        foodRepository: foodRepository,
        inventoryReviewStore: inventoryReviewStore,
        shoppingPlanStore: shoppingPlanStore,
      ),
    );
  }
}

class SmartifyShell extends StatefulWidget {
  const SmartifyShell({
    super.key,
    this.foodRepository,
    this.inventoryReviewStore,
    this.shoppingPlanStore,
  });

  final FoodRepository? foodRepository;
  final InventoryReviewStore? inventoryReviewStore;
  final ShoppingPlanStore? shoppingPlanStore;

  @override
  State<SmartifyShell> createState() => _SmartifyShellState();
}

class _SmartifyShellState extends State<SmartifyShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final FoodRepository _repository;
  List<FoodItem> _foods = [];
  var _plan = ShoppingPlan();
  bool _loading = true;
  bool _busy = false;
  String? _loadError;
  final Set<String> _reviewedItems = {};
  Timer? _inventoryCheckTimer;
  bool _reviewOpen = false;
  final Set<String> _deferredReviewItems = {};
  bool _checkingInventory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = widget.foodRepository ?? InMemoryFoodRepository();
    _initialize();
  }

  Future<void> _initialize() async {
    _inventoryCheckTimer?.cancel();
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      if (widget.shoppingPlanStore case final store?) {
        _plan = await store.load();
      }
      if (widget.inventoryReviewStore case final store?) {
        _reviewedItems.addAll(await store.load());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load saved app data. Please retry.';
        });
      }
      return;
    }
    if (!mounted) return;
    await _loadFoods();
    if (widget.inventoryReviewStore != null) {
      _inventoryCheckTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _checkForNewFoods(),
      );
    }
  }

  void _saveShoppingPlan() {
    final store = widget.shoppingPlanStore;
    if (store == null) return;
    store.save(_plan).catchError((Object error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save shopping list on this device.'),
          action: SnackBarAction(label: 'Retry', onPressed: _saveShoppingPlan),
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkForNewFoods();
  }

  @override
  void dispose() {
    _inventoryCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkForNewFoods() {
    if (!mounted || _busy || _checkingInventory || _reviewOpen) return;
    _loadFoods(showLoading: false);
  }

  void _showPendingReview() {
    _deferredReviewItems.clear();
    _maybeReviewFoods(_foods, manual: true);
  }

  Future<void> _loadFoods({bool showLoading = true}) async {
    if (_checkingInventory) return;
    _checkingInventory = true;
    if (showLoading) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final foods = await _repository.getFoods();
      if (mounted) {
        setState(() => _foods = foods);
        _maybeReviewFoods(foods);
      }
    } catch (_) {
      if (mounted && showLoading) {
        setState(() => _loadError = 'Could not load foods. Please retry.');
      }
    } finally {
      _checkingInventory = false;
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  String _reviewKey(FoodItem food) =>
      '${food.id}:${food.storedAt.toIso8601String()}';

  void _maybeReviewFoods(List<FoodItem> foods, {bool manual = false}) {
    if ((!manual && widget.inventoryReviewStore == null) ||
        _reviewOpen ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final pending = foods
        .where((food) => food.status == FoodStatus.inStock)
        .where((food) => !_reviewedItems.contains(_reviewKey(food)))
        .where((food) => !_deferredReviewItems.contains(_reviewKey(food)))
        .toList();
    if (pending.isEmpty) return;
    _reviewOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == false) {
        _reviewOpen = false;
        return;
      }
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => InventoryReviewPage(
            foods: pending,
            onConfirm: (edits) async {
              for (final edit in edits) {
                final original = pending.firstWhere(
                  (food) => food.id == edit.id,
                );
                if (original.name != edit.name ||
                    original.price != edit.price ||
                    original.category != edit.category) {
                  await _repository.updateFoodDetails(
                    edit.id,
                    name: edit.name,
                    price: edit.price,
                    category: edit.category,
                  );
                }
              }
              final updated = {..._reviewedItems, ...pending.map(_reviewKey)};
              await widget.inventoryReviewStore?.save(updated);
              _reviewedItems
                ..clear()
                ..addAll(updated);
            },
          ),
        ),
      );
      _reviewOpen = false;
      if (confirmed != true) {
        _deferredReviewItems.addAll(pending.map(_reviewKey));
      }
      if (mounted && confirmed == true) _loadFoods(showLoading: false);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
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

  void _removeFood(FoodItem food, FoodStatus outcome) {
    if (_busy || food.status != FoodStatus.inStock) return;
    _changeFoods(
      () async {
        final current = await _repository.getFood(food.id);
        if (current == null || current.status != FoodStatus.inStock) return;
        final wasUseFirst =
            outcome == FoodStatus.consumed &&
            InventoryPriority.priority(current, DateTime.now()) ==
                FoodPriority.first;
        final savedAmount = wasUseFirst ? current.price : 0.0;
        await _repository.updateFood(
          current.copyWith(
            status: outcome,
            savedAmount: savedAmount,
            wasUseFirst: wasUseFirst,
            outcomeAt: DateTime.now(),
          ),
        );
      },
      '${food.name} marked as ${outcome.name}',
      undo: () => _changeFoods(
        () => _repository.updateFood(food),
        '${food.name} restored',
      ),
    );
  }

  Future<void> _editFood(FoodItem food) async {
    if (_busy || _reviewOpen) return;
    _reviewOpen = true;
    try {
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => InventoryReviewPage(
            foods: [food],
            isEditing: true,
            onConfirm: (edits) async {
              final edit = edits.single;
              await _repository.updateFoodDetails(
                food.id,
                name: edit.name,
                price: edit.price,
                category: edit.category,
              );
              if (widget.inventoryReviewStore case final store?) {
                final reviewed = {..._reviewedItems, _reviewKey(food)};
                await store.save(reviewed);
                _reviewedItems
                  ..clear()
                  ..addAll(reviewed);
              }
            },
          ),
        ),
      );
      if (mounted && confirmed == true) {
        await _loadFoods(showLoading: false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Food updated')));
        }
      }
    } finally {
      _reviewOpen = false;
    }
  }

  Future<void> _addFood() async {
    final entry =
        await showDialog<({String name, double price, String category})>(
          context: context,
          builder: (_) => const _AddFoodDialog(),
        );

    if (entry == null || !mounted) return;

    final food = FoodItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: entry.name,
      storedAt: DateTime.now(),
      price: entry.price,
      category: entry.category,
    );

    await _changeFoods(
      () => _repository.addFood(food),
      '${entry.name} added to your fridge',
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFoods = InventoryPriority.sorted(_foods, DateTime.now());
    final pages = [
      HomePage(
        foods: activeFoods,
        allFoods: _foods,
        onViewInventory: () => setState(() => _selectedIndex = 1),
        onViewRecipes: () => setState(() => _selectedIndex = 2),
      ),
      InventoryPage(
        foods: activeFoods,
        onRemove: _removeFood,
        onEdit: _editFood,
        pendingReviewCount: _foods
            .where((food) => food.status == FoodStatus.inStock)
            .where((food) => !_reviewedItems.contains(_reviewKey(food)))
            .length,
        onReviewPending: _showPendingReview,
      ),
      RecipesPage(
        foods: activeFoods,
        active: _selectedIndex == 2,
        plannedIds: _plan.recipes.map((recipe) => recipe.id).toSet(),
        plan: _plan,
        onPlan: (recipe, owned) {
          setState(
            () => _plan.addRecipe(recipe, activeFoods, ownedIngredients: owned),
          );
          _saveShoppingPlan();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe added to Shopping List')),
          );
        },
      ),
      InsightsPage(foods: _foods),
      ShoppingListPage(
        foods: _foods,
        plan: _plan,
        onChanged: () {
          setState(() {});
          _saveShoppingPlan();
        },
      ),
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
                      onPressed: _initialize,
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
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (!_busy) _loadFoods(showLoading: false);
        },
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
            label: 'Accounting',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            selectedIcon: Icon(Icons.shopping_basket),
            label: 'Shopping',
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
  final _price = TextEditingController(text: '0.00');
  final _formKey = GlobalKey<FormState>();
  String _category = 'Other';

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, (
      name: _name.text.trim(),
      price: double.parse(_price.text.trim()),
      category: _category,
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
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Total price',
                    prefixText: '\$ ',
                    helperText: 'Price of this food item.',
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
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categoryIllustrations.keys
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'Other'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Priority uses the expiry date and price.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF58645C)),
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
