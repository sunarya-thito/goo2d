import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

import 'demos/physics/joint/hinge/hinge_demo.dart';
import 'demos/physics/joint/spring/spring_demo.dart';
import 'demos/physics/joint/distance/distance_demo.dart';
import 'demos/physics/collision/shapes/shapes_demo.dart';
import 'demos/physics/collision/trigger/trigger_demo.dart';

class DemoItem {
  final String id;
  final String title;
  final String hint;
  final Widget Function() builder;

  const DemoItem({
    required this.id,
    required this.title,
    required this.hint,
    required this.builder,
  });
}

class DemoSubcategory {
  final String title;
  final List<DemoItem> items;

  const DemoSubcategory({required this.title, required this.items});
}

class DemoCategory {
  final String title;
  final List<DemoSubcategory> subcategories;

  const DemoCategory({required this.title, required this.subcategories});
}

final List<DemoCategory> _demoRegistry = [
  DemoCategory(
    title: 'Physics',
    subcategories: [
      DemoSubcategory(
        title: 'Joint',
        items: [
          DemoItem(
            id: 'hinge',
            title: 'Hinge',
            hint:
                'A blue box is pinned to a fixed anchor (grey dot) by a hinge joint. Gravity swings it like a pendulum.',
            builder: () => const HingeDemo(),
          ),
          DemoItem(
            id: 'spring',
            title: 'Spring',
            hint:
                'A box hangs from a ceiling anchor by a spring joint. Watch it bounce and oscillate as damping slowly settles it.',
            builder: () => const SpringDemo(),
          ),
          DemoItem(
            id: 'distance',
            title: 'Distance',
            hint:
                'Five boxes form a hanging chain linked by distance joints. The top link is static; the rest swing freely under gravity.',
            builder: () => const DistanceDemo(),
          ),
        ],
      ),
      DemoSubcategory(
        title: 'Collision',
        items: [
          DemoItem(
            id: 'shapes',
            title: 'Shapes',
            hint:
                'Circles, boxes, and capsules fall and stack on the ground, showing how different collider shapes interact.',
            builder: () => const ShapesDemo(),
          ),
          DemoItem(
            id: 'trigger',
            title: 'Trigger',
            hint:
                'Boxes fall through the yellow trigger zone. Objects inside turn red; outside they stay grey.',
            builder: () => const TriggerDemo(),
          ),
        ],
      ),
    ],
  ),
];

void main() async {
  await PhysicsSystem.initialize();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemoShell(),
    );
  }
}

class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  bool _sidebarVisible = true;
  DemoItem? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Row(
        children: [
          ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: _sidebarVisible ? 260.0 : 0.0,
              child: SizedBox(
                width: 260,
                child: _Sidebar(
                  categories: _demoRegistry,
                  selected: _selected,
                  onSelect: (item) => setState(() => _selected = item),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _buildContent(),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: Icon(
                      _sidebarVisible ? Icons.menu_open : Icons.menu,
                      color: Colors.white70,
                    ),
                    onPressed: () =>
                        setState(() => _sidebarVisible = !_sidebarVisible),
                    tooltip: _sidebarVisible ? 'Hide sidebar' : 'Show sidebar',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selected == null) {
      return const Center(
        child: Text(
          'Select a demo from the sidebar',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    return Stack(
      children: [
        Game(key: ValueKey(_selected!.id), child: _selected!.builder()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _HintBar(hint: _selected!.hint),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<DemoCategory> categories;
  final DemoItem? selected;
  final void Function(DemoItem) onSelect;

  const _Sidebar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
            child: const Text(
              'goo2d demos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final cat in categories)
                  Theme(
                    data: ThemeData.dark(),
                    child: ExpansionTile(
                      title: Text(
                        cat.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      initiallyExpanded: true,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final sub in cat.subcategories)
                          ExpansionTile(
                            title: Text(
                              sub.title,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            initiallyExpanded: true,
                            tilePadding: const EdgeInsets.only(
                              left: 28,
                              right: 16,
                            ),
                            children: [
                              for (final item in sub.items)
                                ListTile(
                                  contentPadding: const EdgeInsets.only(
                                    left: 44,
                                    right: 16,
                                  ),
                                  dense: true,
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      color: selected?.id == item.id
                                          ? Colors.blue.shade300
                                          : Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                  selected: selected?.id == item.id,
                                  selectedTileColor: const Color(0x264488FF),
                                  onTap: () => onSelect(item),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  final String hint;

  const _HintBar({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xCC0D0D1A),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
