import 'package:flutter/widgets.dart';

import 'package:goo2d/src/object.dart';
import 'package:goo2d/src/element.dart';
import 'package:goo2d/src/render.dart';

abstract class GameWidget extends RenderObjectWidget {
  final int layer;
  final String? name;
  const GameWidget({
    super.key,
    this.layer = RenderLayer.defaultLayer,
    this.name,
  });

  @override
  GameObjectElement createElement() => GameObjectElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GameRenderObject(context as GameObject);
  }

  @override
  void updateRenderObject(BuildContext context, GameRenderObject renderObject) {
    renderObject.object = context as GameObject;
  }

  GameState? createState() => null;
}

abstract class StatefulGameWidget extends GameWidget {
  const StatefulGameWidget({
    super.key,
    super.layer,
    super.name,
  });

  @override
  GameState createState();
}

abstract class StatelessGameWidget extends GameWidget {
  const StatelessGameWidget({
    super.key,
    super.layer,
    super.name,
  });

  Iterable<Widget> build(BuildContext context);

  @override
  GameState createState() => _StatelessGameWidgetState();
}

class _StatelessGameWidgetState extends GameState<StatelessGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) => widget.build(context);
}

class GameObjectWidget extends StatefulGameWidget {
  final List<Widget> children;
  const GameObjectWidget({
    super.key,
    super.layer,
    super.name,
    this.children = const [],
  });

  @override
  GameState createState() => _GameWidgetState();
}

class _GameWidgetState extends GameState<GameObjectWidget> {
  @override
  Iterable<Widget> build(BuildContext context) => widget.children;
}
