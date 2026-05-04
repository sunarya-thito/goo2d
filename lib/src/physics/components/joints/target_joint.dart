import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// The joint attempts to move a Rigidbody2D to a specific target position.
/// 
/// Equivalent to Unity's `TargetJoint2D`.
class TargetJoint extends Component {
  /// The local-space anchor on the rigid-body the joint is attached to.
  Vector2 get anchor => throw UnimplementedError('Implemented via Physics Worker');
  set anchor(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The amount by which the target spring force is reduced in proportion to the movement speed.
  double get dampingRatio => throw UnimplementedError('Implemented via Physics Worker');
  set dampingRatio(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should the target be calculated automatically?
  bool get autoConfigureTarget => throw UnimplementedError('Implemented via Physics Worker');
  set autoConfigureTarget(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The frequency at which the target spring oscillates around the target position.
  double get frequency => throw UnimplementedError('Implemented via Physics Worker');
  set frequency(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The world-space position that the joint will attempt to move the body to.
  Vector2 get target => throw UnimplementedError('Implemented via Physics Worker');
  set target(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum force that can be generated when trying to maintain the target joint constraint.
  double get maxForce => throw UnimplementedError('Implemented via Physics Worker');
  set maxForce(double value) => throw UnimplementedError('Implemented via Physics Worker');

}