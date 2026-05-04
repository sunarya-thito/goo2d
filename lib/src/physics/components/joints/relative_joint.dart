import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Keeps two Rigidbody2D at their relative orientations.
/// 
/// Equivalent to Unity's `RelativeJoint2D`.
class RelativeJoint extends Component {
  /// The current angular offset between the Rigidbody2D that the joint connects.
  double get angularOffset => throw UnimplementedError('Implemented via Physics Worker');
  set angularOffset(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should both the linearOffset and angularOffset be calculated automatically?
  bool get autoConfigureOffset => throw UnimplementedError('Implemented via Physics Worker');
  set autoConfigureOffset(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The world-space position that is currently trying to be maintained.
  Vector2 get target => throw UnimplementedError('Implemented via Physics Worker');
  set target(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The current linear offset between the Rigidbody2D that the joint connects.
  Vector2 get linearOffset => throw UnimplementedError('Implemented via Physics Worker');
  set linearOffset(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum force that can be generated when trying to maintain the relative joint constraint.
  double get maxForce => throw UnimplementedError('Implemented via Physics Worker');
  set maxForce(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum torque that can be generated when trying to maintain the relative joint constraint.
  double get maxTorque => throw UnimplementedError('Implemented via Physics Worker');
  set maxTorque(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Scales both the linear and angular forces used to correct the required relative orientation.
  double get correctionScale => throw UnimplementedError('Implemented via Physics Worker');
  set correctionScale(double value) => throw UnimplementedError('Implemented via Physics Worker');

}