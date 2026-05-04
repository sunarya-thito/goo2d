import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing an arbitrary set of connected edges (lines) defined by its vertices.
/// 
/// Equivalent to Unity's `EdgeCollider2D`.
class EdgeCollider extends Component {
  /// Get or set the points defining multiple continuous edges.
  List<Vector2> get points => throw UnimplementedError('Implemented via Physics Worker');
  set points(List<Vector2> value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Set this to true to use the adjacentEndPoint to form the collision normal that is used to calculate the collision response when a collision occurs at the Edge Collider's end point. Set this to false to not use the adjacentEndPoint, and the collision normal becomes the direction of motion of the collision.
  bool get useAdjacentEndPoint => throw UnimplementedError('Implemented via Physics Worker');
  set useAdjacentEndPoint(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the number of edges.
  int get edgeCount => throw UnimplementedError('Implemented via Physics Worker');
  set edgeCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Defines the position of a virtual point adjacent to the start point of the EdgeCollider2D.
  Vector2 get adjacentStartPoint => throw UnimplementedError('Implemented via Physics Worker');
  set adjacentStartPoint(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Set this to true to use the adjacentStartPoint to form the collision normal that is used to calculate the collision response when a collision occurs at the Edge Collider's start point. Set this to false to not use the adjacentStartPoint, and the collision normal becomes the direction of motion of the collision.
  bool get useAdjacentStartPoint => throw UnimplementedError('Implemented via Physics Worker');
  set useAdjacentStartPoint(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Defines the position of a virtual point adjacent to the end point of the EdgeCollider2D.
  Vector2 get adjacentEndPoint => throw UnimplementedError('Implemented via Physics Worker');
  set adjacentEndPoint(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the number of points.
  int get pointCount => throw UnimplementedError('Implemented via Physics Worker');
  set pointCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the radius of all edges created by the collider.
  double get edgeRadius => throw UnimplementedError('Implemented via Physics Worker');
  set edgeRadius(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Reset to a single edge consisting of two points.
  void reset() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets all the points that define a set of continuous edges.
  /// - [points]: A list of Vector2 used to receive the points.
  int getPoints(List<Vector2> points) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Sets all the points that define a set of continuous edges.
  /// - [points]: A list of Vector2 used to set the points. This list must contain at least two points.
  bool setPoints(List<Vector2> points) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}