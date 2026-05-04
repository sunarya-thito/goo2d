import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that restricts the motion of a Rigidbody2D object to a single line.
/// 
/// Equivalent to Unity's `SliderJoint2D`.
class SliderJoint extends Component {
  /// Should a motor force be applied automatically to the Rigidbody2D?
  bool get useMotor => throw UnimplementedError('Implemented via Physics Worker');
  set useMotor(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The current joint translation.
  double get jointTranslation => throw UnimplementedError('Implemented via Physics Worker');
  set jointTranslation(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angle of the line in space (in degrees).
  double get angle => throw UnimplementedError('Implemented via Physics Worker');
  set angle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should motion limits be used?
  bool get useLimits => throw UnimplementedError('Implemented via Physics Worker');
  set useLimits(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should the angle be calculated automatically?
  bool get autoConfigureAngle => throw UnimplementedError('Implemented via Physics Worker');
  set autoConfigureAngle(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Restrictions on how far the joint can slide in each direction along the line.
  int get limits => throw UnimplementedError('Implemented via Physics Worker');
  set limits(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the state of the joint limit.
  JointLimitState get limitState => throw UnimplementedError('Implemented via Physics Worker');
  set limitState(JointLimitState value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Parameters for a motor force that is applied automatically to the Rigibody2D along the line.
  int get motor => throw UnimplementedError('Implemented via Physics Worker');
  set motor(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angle (in degrees) referenced between the two bodies used as the constraint for the joint.
  double get referenceAngle => throw UnimplementedError('Implemented via Physics Worker');
  set referenceAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The current joint speed.
  double get jointSpeed => throw UnimplementedError('Implemented via Physics Worker');
  set jointSpeed(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the motor force of the joint given the specified timestep.
  /// - [timeStep]: The time to calculate the motor force for.
  double getMotorForce(double timeStep) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}