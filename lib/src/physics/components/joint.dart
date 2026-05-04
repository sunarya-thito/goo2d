import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Parent class for joints to connect Rigidbody2D objects.
/// 
/// Equivalent to Unity's `Joint2D`.
class Joint extends Component {
  /// Gets the reaction torque of the joint.
  double get reactionTorque => throw UnimplementedError('Implemented via Physics Worker');
  set reactionTorque(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Rigidbody2D attached to the Joint2D.
  Rigidbody get attachedRigidbody => throw UnimplementedError('Implemented via Physics Worker');
  set attachedRigidbody(Rigidbody value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The action to take when the joint breaks the breakForce or breakTorque.
  int get breakAction => throw UnimplementedError('Implemented via Physics Worker');
  set breakAction(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the reaction force of the joint.
  Vector2 get reactionForce => throw UnimplementedError('Implemented via Physics Worker');
  set reactionForce(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The torque that needs to be applied for this joint to break.
  double get breakTorque => throw UnimplementedError('Implemented via Physics Worker');
  set breakTorque(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The force that needs to be applied for this joint to break.
  double get breakForce => throw UnimplementedError('Implemented via Physics Worker');
  set breakForce(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Rigidbody2D object to which the other end of the joint is attached (ie, the object without the joint component).
  Rigidbody get connectedBody => throw UnimplementedError('Implemented via Physics Worker');
  set connectedBody(Rigidbody value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should the two Rigidbody2D connected with this joint collide with each other?
  bool get enableCollision => throw UnimplementedError('Implemented via Physics Worker');
  set enableCollision(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the reaction torque of the joint given the specified timeStep.
  /// - [timeStep]: The time to calculate the reaction torque for.
  double getReactionTorque(double timeStep) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets the reaction force of the joint given the specified timeStep.
  /// - [timeStep]: The time to calculate the reaction force for.
  Vector2 getReactionForce(double timeStep) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}