import 'package:flutter/widgets.dart';

import 'package:goo2d/src/object.dart';
import 'package:goo2d/src/element.dart';
import 'package:goo2d/src/render.dart';

/// Base class for all widgets that represent objects in the Goo2D scene hierarchy.
abstract class GameWidget extends RenderObjectWidget {
  /// The rendering layer of this object.
  final int layer;

  /// The user-defined name of this object.
  final String? name;

  /// Creates a [GameWidget].
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

  /// Creates the [GameState] instance for this widget.
  ///
  /// Subclasses of [StatefulGameWidget] must override this.
  GameState? createState() => null;
}

/// A base class for [GameObject]s that maintain mutable state.
abstract class StatefulGameWidget extends GameWidget {
  /// Creates a stateful game widget.
  const StatefulGameWidget({
    super.key,
    super.layer,
    super.name,
  });

  @override
  GameState createState();
}

abstract class StatelessGameWidget extends GameWidget {
  /// Creates a stateless game widget.
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

/// A standard implementation of [StatefulGameWidget] that configures
/// components and children objects declaratively.
class GameObjectWidget extends StatefulGameWidget {
  /// The child widgets (sub-objects) of this object.
  final List<Widget> children;

  /// Creates a [GameObjectWidget].
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
