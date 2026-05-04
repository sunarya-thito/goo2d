import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Applies both force and torque to reduce both the linear and angular velocities to zero.
/// 
/// Equivalent to Unity's `FrictionJoint2D`.
class FrictionJoint extends Component {
  /// The maximum torque that can be generated when trying to maintain the friction joint constraint.
  double get maxTorque => throw UnimplementedError('Implemented via Physics Worker');
  set maxTorque(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum force that can be generated when trying to maintain the friction joint constraint.
  double get maxForce => throw UnimplementedError('Implemented via Physics Worker');
  set maxForce(double value) => throw UnimplementedError('Implemented via Physics Worker');

}