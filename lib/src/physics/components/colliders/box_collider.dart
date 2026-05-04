import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing an axis-aligned rectangle.
/// 
/// Equivalent to Unity's `BoxCollider2D`.
class BoxCollider extends Component {
  /// Controls the radius of all edges created by the collider.
  double get edgeRadius => throw UnimplementedError('Implemented via Physics Worker');
  set edgeRadius(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The width and height of the rectangle.
  Vector2 get size => throw UnimplementedError('Implemented via Physics Worker');
  set size(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Determines whether the BoxCollider2D's shape is automatically updated based on a SpriteRenderer's tiling properties.
  bool get autoTiling => throw UnimplementedError('Implemented via Physics Worker');
  set autoTiling(bool value) => throw UnimplementedError('Implemented via Physics Worker');

}