import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Represents an efficient low-level physics shape used by the physics engine.
///
/// Equivalent to Unity's `PhysicsShape2D`.
class PhysicsShape {
  PhysicsShape({
    this.shapeType = PhysicsShapeType.polygon,
    this.useAdjacentStart = false,
    this.radius = 0.0,
    this.useAdjacentEnd = false,
    this.vertexStartIndex = 0,
    this.vertexCount = 0,
  }) : adjacentEnd = Vector2.zero(), adjacentStart = Vector2.zero();

  /// The shape type determines how the vertices and radius are used.
  PhysicsShapeType shapeType;

  /// Whether the shape uses the adjacentStart feature.
  bool useAdjacentStart;

  /// The radius of the shape.
  double radius;

  /// Defines the position of a virtual point adjacent to the end vertex.
  Vector2 adjacentEnd;

  /// Whether the shape uses the adjacentEnd feature.
  bool useAdjacentEnd;

  /// The start index for the geometry of this shape within the PhysicsShapeGroup2D.
  int vertexStartIndex;

  /// The total number of vertices used to represent the shape type.
  int vertexCount;

  /// Defines the position of a virtual point adjacent to the start vertex.
  Vector2 adjacentStart;
}
