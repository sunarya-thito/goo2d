import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing an circle.
/// 
/// Equivalent to Unity's `CircleCollider2D`.
class CircleCollider extends Component {
  /// Radius of the circle.
  double get radius => throw UnimplementedError('Implemented via Physics Worker');
  set radius(double value) => throw UnimplementedError('Implemented via Physics Worker');

}