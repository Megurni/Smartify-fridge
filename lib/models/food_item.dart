part of '../main.dart';

enum FoodPriority { first, soon, later }

class FoodItem {
  const FoodItem({
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.daysLeft,
    required this.price,
    required this.priority,
    required this.category,
  });

  final String name;
  final String emoji;
  final String quantity;
  final int daysLeft;
  final double price;
  final FoodPriority priority;
  final String category;
}

const demoFoods = [
  FoodItem(
    name: 'Chicken breast',
    emoji: '🍗',
    quantity: '2 pieces',
    daysLeft: 1,
    price: 8.50,
    priority: FoodPriority.first,
    category: 'Meat',
  ),
  FoodItem(
    name: 'Baby spinach',
    emoji: '🥬',
    quantity: '1 bag',
    daysLeft: 2,
    price: 4.20,
    priority: FoodPriority.first,
    category: 'Produce',
  ),
  FoodItem(
    name: 'Mushrooms',
    emoji: '🍄',
    quantity: '250 g',
    daysLeft: 3,
    price: 3.80,
    priority: FoodPriority.soon,
    category: 'Produce',
  ),
  FoodItem(
    name: 'Greek yogurt',
    emoji: '🥛',
    quantity: '3 cups',
    daysLeft: 5,
    price: 5.40,
    priority: FoodPriority.soon,
    category: 'Dairy',
  ),
  FoodItem(
    name: 'Carrots',
    emoji: '🥕',
    quantity: '6 pieces',
    daysLeft: 9,
    price: 2.60,
    priority: FoodPriority.later,
    category: 'Produce',
  ),
  FoodItem(
    name: 'Eggs',
    emoji: '🥚',
    quantity: '8 eggs',
    daysLeft: 12,
    price: 4.90,
    priority: FoodPriority.later,
    category: 'Dairy',
  ),
];
