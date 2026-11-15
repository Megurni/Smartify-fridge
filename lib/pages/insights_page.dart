part of '../main.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key, required this.foods});

  final List<FoodItem> foods;

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  AccountingPeriod _period = AccountingPeriod.thisWeek;

  @override
  Widget build(BuildContext context) {
    final periodFoods =
        widget.foods
            .where((food) => _period.contains(food, DateTime.now()))
            .toList()
          ..sort(
            (a, b) => (b.outcomeAt ?? DateTime.now()).compareTo(
              a.outcomeAt ?? DateTime.now(),
            ),
          );
    final consumed = periodFoods
        .where((food) => food.status == FoodStatus.consumed)
        .toList();
    final discarded = periodFoods
        .where((food) => food.status == FoodStatus.discarded)
        .toList();
    final saved = consumed.fold<double>(
      0,
      (total, food) => total + food.savedAmount,
    );
    final wasted = discarded.fold<double>(
      0,
      (total, food) => total + food.price,
    );

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(
            title: 'Food accounting',
            subtitle: 'Totals from recorded food outcomes',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          sliver: SliverList.list(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<AccountingPeriod>(
                  value: _period,
                  items: AccountingPeriod.values
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text(period.label),
                        ),
                      )
                      .toList(),
                  onChanged: (period) {
                    if (period != null) setState(() => _period = period);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _AccountingHero(saved: saved, wasted: wasted),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.check_circle_outline,
                      value: '${consumed.length}',
                      label: 'Items consumed',
                      color: const Color(0xFF28655A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.delete_outline,
                      value: '${discarded.length}',
                      label: 'Items discarded',
                      color: const Color(0xFFD87C4A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Only food consumed while it is in Use First counts as saved. Other consumed food adds no savings. Discarded food counts as wasted.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Text('History', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (periodFoods.isEmpty)
                const Text('No recorded food outcomes in this period.')
              else
                ...periodFoods.map((food) {
                  final date = (food.outcomeAt ?? DateTime.now()).toLocal();
                  final consumed = food.status == FoodStatus.consumed;
                  return Card(
                    child: ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${consumed ? 'Consumed' : 'Discarded'} · ${date.month}/${date.day}/${date.year}',
                      ),
                      trailing: Text(
                        consumed
                            ? (food.savedAmount > 0
                                  ? '\$${food.savedAmount.toStringAsFixed(2)} saved'
                                  : 'No savings')
                            : '\$${food.price.toStringAsFixed(2)} wasted',
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountingHero extends StatelessWidget {
  const _AccountingHero({required this.saved, required this.wasted});

  final double saved;
  final double wasted;

  static const _savedColor = Color(0xFF86E0BB);
  static const _wastedColor = Color(0xFFF2B866);

  @override
  Widget build(BuildContext context) {
    final total = saved + wasted;
    final savedPercent = total == 0 ? 0 : (saved / total * 100).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF28655A), Color(0xFF173F39)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text(
            'SAVED VS WASTED',
            style: TextStyle(
              color: Color(0xFFCAE2D5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            label:
                'Saved from waste \$${saved.toStringAsFixed(2)}, wasted \$${wasted.toStringAsFixed(2)}',
            child: SizedBox(
              width: 184,
              height: 184,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(184),
                    painter: _AccountingRingPainter(
                      saved: saved,
                      wasted: wasted,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total == 0 ? '—' : '$savedPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        total == 0 ? 'No outcomes yet' : 'saved share',
                        style: const TextStyle(
                          color: Color(0xFFCAE2D5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _AccountingLegend(
            label: 'Saved from waste',
            amount: saved,
            color: _savedColor,
          ),
          const SizedBox(height: 10),
          _AccountingLegend(
            label: 'Wasted',
            amount: wasted,
            color: _wastedColor,
          ),
        ],
      ),
    );
  }
}

class _AccountingLegend extends StatelessWidget {
  const _AccountingLegend({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
      Text(
        '\$${amount.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _AccountingRingPainter extends CustomPainter {
  const _AccountingRingPainter({required this.saved, required this.wasted});

  final double saved;
  final double wasted;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(
      center: center,
      radius: math.min(size.width, size.height) / 2 - 11,
    );
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = saved + wasted;
    if (total <= 0) return;
    final savedSweep = math.pi * 2 * saved / total;
    final savedPaint = Paint()
      ..color = _AccountingHero._savedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    final wastedPaint = Paint()
      ..color = _AccountingHero._wastedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    const start = -math.pi / 2;
    if (saved > 0) canvas.drawArc(rect, start, savedSweep, false, savedPaint);
    if (wasted > 0) {
      canvas.drawArc(
        rect,
        start + savedSweep,
        math.pi * 2 - savedSweep,
        false,
        wastedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AccountingRingPainter oldDelegate) =>
      oldDelegate.saved != saved || oldDelegate.wasted != wasted;
}
