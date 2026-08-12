part of 'main.dart';

class SmartifyApp extends StatelessWidget {
  const SmartifyApp({super.key});

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
      home: const SmartifyShell(),
    );
  }
}

class SmartifyShell extends StatefulWidget {
  const SmartifyShell({super.key});

  @override
  State<SmartifyShell> createState() => _SmartifyShellState();
}

class _SmartifyShellState extends State<SmartifyShell> {
  int _selectedIndex = 0;
  final List<FoodItem> _foods = List.of(demoFoods);

  void _removeFood(FoodItem food, String outcome) {
    setState(() => _foods.remove(food));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${food.name} marked as $outcome'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => setState(() => _foods.add(food)),
          ),
        ),
      );
  }

  void _addDemoFood() {
    const newFood = FoodItem(
      name: 'Fresh strawberries',
      emoji: '🍓',
      quantity: '1 box',
      daysLeft: 4,
      price: 5.20,
      priority: FoodPriority.soon,
      category: 'Produce',
    );
    setState(() {
      if (!_foods.any((food) => food.name == newFood.name)) {
        _foods.add(newFood);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Strawberries added to your fridge')),
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
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _addDemoFood,
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
