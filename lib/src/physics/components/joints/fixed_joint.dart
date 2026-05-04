import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Connects two Rigidbody2D together at their anchor points using a configurable spring.
/// 
/// Equivalent to Unity's `FixedJoint2D`.
class FixedJoint extends Component {
  /// The frequency at which the spring oscillates around the distance between the objects.
  double get frequency => throw UnimplementedError('Implemented via Physics Worker');
  set frequency(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angle referenced between the two bodies used as the constraint for the joint.
  double get referenceAngle => throw UnimplementedError('Implemented via Physics Worker');
  set referenceAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The amount by which the spring force is reduced in proportion to the movement speed.
  double get dampingRatio => throw UnimplementedError('Implemented via Physics Worker');
  set dampingRatio(double value) => throw UnimplementedError('Implemented via Physics Worker');

}