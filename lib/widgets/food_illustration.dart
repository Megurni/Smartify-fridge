import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../repositories/food_illustrations.dart';

class FoodIllustration extends StatefulWidget {
  const FoodIllustration({
    super.key,
    required this.name,
    required this.category,
    this.size = 32,
  });
  final String name;
  final String category;
  final double size;
  @override
  State<FoodIllustration> createState() => _FoodIllustrationState();
}

class _FoodIllustrationState extends State<FoodIllustration> {
  late Future<String?> _image;
  static const bundled = {
    'cut-of-meat',
    'fish',
    'glass-of-milk',
    'egg',
    'red-apple',
    'broccoli',
    'bread',
    'shallow-pan-of-food',
    'beverage-box',
    'salt',
    'fork-and-knife-with-plate',
    'carrot',
    'brown-mushroom',
    'leafy-green',
    'poultry-leg',
  };
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FoodIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) _load();
  }

  void _load() {
    final id = illustrationName(widget.name).replaceAll(' ', '-');
    _image = bundled.contains(id)
        ? Future.value(null)
        : FoodIllustrations.instance.find(widget.name);
  }

  @override
  Widget build(BuildContext context) {
    final id = illustrationName(widget.name).replaceAll(' ', '-');
    final fallback = SvgPicture.asset(
      'assets/food_icons/${bundled.contains(id) ? id : categoryIllustration(widget.category)}.svg',
      width: widget.size,
      height: widget.size,
    );
    return Semantics(
      label: widget.name,
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: FutureBuilder<String?>(
          future: _image,
          builder: (context, snapshot) => snapshot.data == null
              ? fallback
              : SvgPicture.string(
                  snapshot.data!,
                  width: widget.size,
                  height: widget.size,
                  placeholderBuilder: (_) => fallback,
                  errorBuilder: (_, error, stack) => fallback,
                ),
        ),
      ),
    );
  }
}

class FridgePhoto extends StatelessWidget {
  const FridgePhoto({super.key, required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    Widget placeholder(String message) => Container(
      height: 100,
      width: double.infinity,
      alignment: Alignment.center,
      color: const Color(0xFFF0F3EF),
      child: Text(message),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fridge photo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: url.isEmpty
              ? placeholder('No fridge photo available')
              : Image.network(
                  url,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : placeholder('Loading fridge photo…'),
                  errorBuilder: (_, error, stack) =>
                      placeholder('Fridge photo unavailable'),
                ),
        ),
        if (url.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Full shelf capture — may contain multiple foods.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
