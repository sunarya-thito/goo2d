import 'package:flutter/widgets.dart';

import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/object.dart';
import 'package:goo2d/src/element.dart';
import 'package:goo2d/src/render.dart';

/// Base class for all widgets that represent objects in the Goo2D scene hierarchy.
abstract class GameObjectWidget extends RenderObjectWidget {
  /// The rendering layer of this object.
  final int layer;

  /// The user-defined name of this object.
  final String? name;

  /// Creates a [GameObjectWidget].
  const GameObjectWidget({
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
abstract class StatefulGameWidget extends GameObjectWidget {
  /// Creates a stateful game widget.
  const StatefulGameWidget({
    super.key,
    super.layer,
    super.name,
  });

  @override
  GameState createState();
}

/// A standard implementation of [StatefulGameWidget] that configures
/// components and children objects declaratively.
class GameWidget extends StatefulGameWidget {
  /// A factory that provides the initial components for this object.
  final Iterable<GameComponent> components;

  /// The child widgets (sub-objects) of this object.
  final List<Widget> children;

  /// Creates a [GameWidget].
  const GameWidget({
    super.key,
    super.layer,
    super.name,
    this.components = const [],
    this.children = const [],
  });

  @override
  GameState createState() => _GameWidgetState();
}

class _GameWidgetState extends GameState<GameWidget> {
  @override
  void initState() {
    super.initState();
    for (var component in widget.components) {
      assert(
        internalType(component) != GameState &&
            internalType(component) != _GameWidgetState,
        'GameState components are managed by the engine and cannot be added manually via GameWidget.components.',
      );
      final comp = internalCreateComponent(component);
      addComponent(comp);
    }
  }

  @override
  void didUpdateWidget(covariant GameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newComponents = widget.components;

    for (final component in components) {
      if (component is GameState) continue;
      final newOne = _getNewOne(component.runtimeType, newComponents);
      if (newOne == null) {
        removeComponent(component);
      }
    }

    for (final component in widget.components) {
      assert(
        internalType(component) != GameState &&
            internalType(component) != _GameWidgetState,
        'GameState components are managed by the engine and cannot be added manually via GameWidget.components.',
      );
      final (oldOne, factory) = getOldOne(component, components);
      if (oldOne == null) {
        addComponent(internalCreateComponent(component));
      } else if (factory != null && factory.update) {
        factory.apply(oldOne);
      } else {
        addComponent(component);
      }
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) => widget.children;
}

GameComponent? _getNewOne(Type type, Iterable<GameComponent> list) {
  for (final component in list) {
    if (type == internalType(component)) {
      return component;
    }
  }
  return null;
}

(Component?, ComponentFactoryWithParams?) getOldOne(
  GameComponent newComponent,
  Iterable<Component> list,
) {
  final newRuntimeType = internalType(newComponent);
  for (final component in list) {
    if (component.runtimeType == newRuntimeType) {
      if (newComponent is ComponentFactoryWithParams) {
        return (component, newComponent);
      } else {
        return (component, null);
      }
    }
  }
  return (null, null);
}
