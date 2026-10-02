part of '../main.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key, required this.foods, this.active = true});

  final List<FoodItem> foods;
  final bool active;

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final _repository = RecipeRepository();
  final _searchController = TextEditingController();

  List<RecipeMatch> _matches = [];
  bool _loading = false;
  String? _error;
  String? _loadedKey;
  String? _selectedIngredient;
  String _query = '';
  int _request = 0;

  String get _foodKey => widget.foods
      .map(
        (food) =>
            '${food.id}:${food.name}:${food.priority.index}:${food.daysLeft}',
      )
      .join('|');

  // Keep one chip per ingredient, even if inventory has duplicate entries.
  Map<String, String> get _inventoryIngredients {
    final names = <String, String>{};

    for (final food in widget.foods) {
      names.putIfAbsent(ingredientKey(food.name), () => food.name);
    }

    return names;
  }

  // Text search filters the currently loaded recipe results.
  List<RecipeMatch> get _visibleMatches {
    final query = ingredientKey(_query);

    if (query.isEmpty) {
      return _matches;
    }

    return _matches.where((match) {
      final nameMatches = match.recipe.name.toLowerCase().contains(
        _query.trim().toLowerCase(),
      );

      final ingredientMatches = match.recipe.ingredients.any(
        (ingredient) => ingredientKey(ingredient.name).contains(query),
      );

      return nameMatches || ingredientMatches;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    if (widget.active) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant RecipesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear the selection if that ingredient was removed from inventory.
    if (_selectedIngredient != null &&
        !_inventoryIngredients.containsKey(_selectedIngredient)) {
      _selectedIngredient = null;
      _loadedKey = null;
    }

    if (widget.active && _loadedKey != _foodKey) {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _repository.close();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    _loadedKey = _foodKey;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final matches = await _repository.recommend(
        widget.foods,
        ingredient: _selectedIngredient,
      );

      // Ignore older requests if the user switches filters quickly.
      if (mounted && request == _request) {
        setState(() => _matches = matches);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _error = 'Could not load recipes. Check your connection and retry.';
        });
      }
    } finally {
      if (mounted && request == _request) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectIngredient(String? ingredient) {
    if (_selectedIngredient == ingredient) {
      return;
    }

    setState(() {
      _selectedIngredient = ingredient;
    });

    _load();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = _inventoryIngredients;
    final visibleMatches = _visibleMatches;

    final filtering = _selectedIngredient != null || _query.trim().isNotEmpty;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(
            title: 'Cook what you have',
            subtitle: 'Recipes using food that needs attention',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          sliver: SliverList.list(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _query = value);
                },
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: 'Search these recipes or ingredients',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(
                      color: Color(0xFF28655A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'In your fridge',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF58645C),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ingredientChip(label: 'All', ingredient: null),
                  for (final entry in ingredients.entries)
                    _ingredientChip(label: entry.value, ingredient: entry.key),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      filtering ? 'Search results' : 'Recommended recipes',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!_loading && _error == null)
                    Text(
                      '${visibleMatches.length} recipes',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _selectedIngredient == null
                    ? 'Use First ingredients come first, then Use Soon '
                          'and fewer missing ingredients.'
                    : 'Recipes using '
                          '${ingredients[_selectedIngredient] ?? _selectedIngredient}.',
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _messageCard(
                  icon: Icons.wifi_off_rounded,
                  message: _error!,
                  action: TextButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                )
              else if (widget.foods.isEmpty)
                _messageCard(
                  icon: Icons.kitchen_outlined,
                  message: 'Add food to your inventory to find recipes.',
                )
              else if (visibleMatches.isEmpty)
                _messageCard(
                  icon: Icons.search_off_rounded,
                  message: _query.trim().isNotEmpty
                      ? 'No loaded recipes match your search. '
                            'Try another word or ingredient chip.'
                      : 'No recipes found for these ingredients. '
                            'Try another ingredient chip.',
                  action: _query.trim().isNotEmpty
                      ? TextButton(
                          onPressed: _clearSearch,
                          child: const Text('Clear search'),
                        )
                      : null,
                )
              else
                for (final match in visibleMatches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _RecipeCard(match: match),
                  ),
              const SizedBox(height: 12),
              const Text(
                'Recipes and photos: TheMealDB\n'
                'Ingredient matches are based on names. '
                'Check quantities before cooking.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ingredientChip({required String label, required String? ingredient}) {
    return FilterChip(
      label: Text(label),
      selected: _selectedIngredient == ingredient,
      onSelected: (_) => _selectIngredient(ingredient),
      showCheckmark: true,
      selectedColor: const Color(0xFFD5EAE1),
      backgroundColor: const Color(0xFFF7F8F3),
      checkmarkColor: const Color(0xFF28655A),
      labelStyle: const TextStyle(
        color: Color(0xFF264B3D),
        fontWeight: FontWeight.w600,
      ),
      side: const BorderSide(color: Color(0xFFD5DDD5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF789182)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }
}

class _RecipePhoto extends StatelessWidget {
  const _RecipePhoto(this.url, {this.size = 120});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => Container(
            color: const Color(0xFFE4EBDF),
            alignment: Alignment.center,
            child: const Icon(
              Icons.restaurant_rounded,
              size: 36,
              color: Color(0xFF789182),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final recipe = match.recipe;

    // Display up to three matching ingredients as green badges.
    final matchedNames = match.available
        .map((ingredient) => ingredient.name)
        .toSet()
        .toList();

    final preview = match.missing
        .take(3)
        .map((ingredient) => ingredient.name)
        .join(', ');

    final extraCount = match.missing.length > 3 ? match.missing.length - 3 : 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _RecipeDetails(match: match),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 450;
              final photoSize = compact ? 88.0 : 120.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RecipePhoto(recipe.image, size: photoSize),
                  SizedBox(width: compact ? 12 : 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 16 : 19,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        if (matchedNames.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final name in matchedNames.take(3))
                                _IngredientBadge(name: name),
                              if (matchedNames.length > 3)
                                Text(
                                  '+${matchedNames.length - 3} more in fridge',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF28655A),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          preview.isEmpty
                              ? 'All ingredient names match your fridge'
                              : 'Need: $preview',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        if (extraCount > 0)
                          Text(
                            '+$extraCount more ingredients needed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        if (match.useFirst > 0 || match.useSoon > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            [
                              if (match.useFirst > 0)
                                '${match.useFirst} Use First',
                              if (match.useSoon > 0)
                                '${match.useSoon} Use Soon',
                            ].join(' · '),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF28655A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF58645C),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IngredientBadge extends StatelessWidget {
  const _IngredientBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F0E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '✓ $name',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF28655A),
        ),
      ),
    );
  }
}

class _RecipeDetails extends StatelessWidget {
  const _RecipeDetails({required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final recipe = match.recipe;

    return AlertDialog(
      title: Text(recipe.name),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth < 280
                      ? constraints.maxWidth
                      : 280.0;

                  return Center(child: _RecipePhoto(recipe.image, size: size));
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingredients',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Have = matching name in your fridge. '
                'Check the quantity needed.',
              ),
              const SizedBox(height: 12),
              for (final item in recipe.ingredients)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '${match.available.contains(item) ? 'Have' : 'Need'}'
                    ' · ${item.measure} ${item.name}',
                    style: TextStyle(
                      color: match.available.contains(item)
                          ? const Color(0xFF28655A)
                          : null,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Instructions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(
                recipe.instructions.isEmpty
                    ? 'No instructions provided for this recipe.'
                    : recipe.instructions,
                style: const TextStyle(height: 1.6),
              ),
              const SizedBox(height: 20),
              const Text(
                'Recipe and photo provided by TheMealDB.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
