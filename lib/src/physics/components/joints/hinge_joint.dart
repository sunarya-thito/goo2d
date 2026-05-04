import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that allows a Rigidbody2D object to rotate around a point in space or a point on another object.
/// 
/// Equivalent to Unity's `HingeJoint2D`.
class HingeJoint extends Component {
  /// The current joint speed.
  double get jointSpeed => throw UnimplementedError('Implemented via Physics Worker');
  set jointSpeed(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls whether the connected anchor is used or not.
  bool get useConnectedAnchor => throw UnimplementedError('Implemented via Physics Worker');
  set useConnectedAnchor(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angle (in degrees) referenced between the two bodies used as the constraint for the joint.
  double get referenceAngle => throw UnimplementedError('Implemented via Physics Worker');
  set referenceAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should limits be placed on the range of rotation?
  bool get useLimits => throw UnimplementedError('Implemented via Physics Worker');
  set useLimits(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Parameters for the motor force applied to the joint.
  int get motor => throw UnimplementedError('Implemented via Physics Worker');
  set motor(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Limit of angular rotation (in degrees) on the joint.
  int get limits => throw UnimplementedError('Implemented via Physics Worker');
  set limits(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The current joint angle (in degrees) with respect to the reference angle.
  double get jointAngle => throw UnimplementedError('Implemented via Physics Worker');
  set jointAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should the joint be rotated automatically by a motor torque?
  bool get useMotor => throw UnimplementedError('Implemented via Physics Worker');
  set useMotor(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the state of the joint limit.
  JointLimitState get limitState => throw UnimplementedError('Implemented via Physics Worker');
  set limitState(JointLimitState value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the motor torque of the joint given the specified timestep.
  /// - [timeStep]: The time to calculate the motor torque for.
  double getMotorTorque(double timeStep) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}