import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// The wheel joint allows the simulation of wheels by providing a constraining suspension motion with an optional motor.
/// 
/// Equivalent to Unity's `WheelJoint2D`.
class WheelJoint extends Component {
  /// The current joint angle (in degrees) defined as the relative angle between the two Rigidbody2D that the joint connects to.
  double get jointAngle => throw UnimplementedError('Implemented via Physics Worker');
  set jointAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The current joint linear speed in meters/sec.
  double get jointLinearSpeed => throw UnimplementedError('Implemented via Physics Worker');
  set jointLinearSpeed(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The current joint rotational speed in degrees/sec.
  double get jointSpeed => throw UnimplementedError('Implemented via Physics Worker');
  set jointSpeed(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The current joint translation.
  double get jointTranslation => throw UnimplementedError('Implemented via Physics Worker');
  set jointTranslation(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Parameters for a motor force that is applied automatically to the Rigidbody2D along the line.
  int get motor => throw UnimplementedError('Implemented via Physics Worker');
  set motor(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should a motor force be applied automatically to the Rigidbody2D?
  bool get useMotor => throw UnimplementedError('Implemented via Physics Worker');
  set useMotor(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Set the joint suspension configuration.
  int get suspension => throw UnimplementedError('Implemented via Physics Worker');
  set suspension(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the motor torque of the joint given the specified timestep.
  /// - [timeStep]: The time to calculate the motor torque for.
  double getMotorTorque(double timeStep) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}