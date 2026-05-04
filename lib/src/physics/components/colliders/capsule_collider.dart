import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// A capsule-shaped primitive collider.
/// 
/// Equivalent to Unity's `CapsuleCollider2D`.
class CapsuleCollider extends Component {
  /// The width and height of the capsule area.
  Vector2 get size => throw UnimplementedError('Implemented via Physics Worker');
  set size(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The direction that the capsule sides can extend.
  CapsuleDirection get direction => throw UnimplementedError('Implemented via Physics Worker');
  set direction(CapsuleDirection value) => throw UnimplementedError('Implemented via Physics Worker');

}