import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Represents an efficient low-level physics shape used by the physics engine.
/// 
/// Equivalent to Unity's `PhysicsShape2D`.
class PhysicsShape {
  /// The shape type determines how the vertices and radius are used by this PhysicsShape2D.
  PhysicsShapeType get shapeType => throw UnimplementedError('Implemented via Physics Worker');
  set shapeType(PhysicsShapeType value) => throw UnimplementedError('Implemented via Physics Worker');

  /// When the value is true, then the shape will use the adjacentStart feature. When the value is false, then the shape will not use the adjacentStart feature.
  bool get useAdjacentStart => throw UnimplementedError('Implemented via Physics Worker');
  set useAdjacentStart(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The radius of the shape.
  double get radius => throw UnimplementedError('Implemented via Physics Worker');
  set radius(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Defines the position of a virtual point adjacent to the end vertex of an edge shape.
  Vector2 get adjacentEnd => throw UnimplementedError('Implemented via Physics Worker');
  set adjacentEnd(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// When the value is true, then the shape will use the adjacentEnd feature. When the value is false, then the shape will not use the adjacentEnd feature.
  bool get useAdjacentEnd => throw UnimplementedError('Implemented via Physics Worker');
  set useAdjacentEnd(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The start index for the geometry of this shape within the PhysicsShapeGroup2D.
  int get vertexStartIndex => throw UnimplementedError('Implemented via Physics Worker');
  set vertexStartIndex(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The total number of vertices used to represent the shape type.
  int get vertexCount => throw UnimplementedError('Implemented via Physics Worker');
  set vertexCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Defines the position of a virtual point adjacent to the start vertex of an edge shape.
  Vector2 get adjacentStart => throw UnimplementedError('Implemented via Physics Worker');
  set adjacentStart(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

}