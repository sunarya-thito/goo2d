import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Applies forces to attract/repulse against a point.
/// 
/// Equivalent to Unity's `PointEffector2D`.
class PointEffector extends Component {
  /// The scale applied to the calculated distance between source and target.
  double get distanceScale => throw UnimplementedError('Implemented via Physics Worker');
  set distanceScale(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The mode used to apply the effector force.
  EffectorForceMode get forceMode => throw UnimplementedError('Implemented via Physics Worker');
  set forceMode(EffectorForceMode value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The target for where the effector applies any force.
  EffectorSelection get forceTarget => throw UnimplementedError('Implemented via Physics Worker');
  set forceTarget(EffectorSelection value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The variation of the magnitude of the force to be applied.
  double get forceVariation => throw UnimplementedError('Implemented via Physics Worker');
  set forceVariation(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The magnitude of the force to be applied.
  double get forceMagnitude => throw UnimplementedError('Implemented via Physics Worker');
  set forceMagnitude(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angular damping to apply to rigid-bodies.
  double get angularDamping => throw UnimplementedError('Implemented via Physics Worker');
  set angularDamping(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The source which is used to calculate the centroid point of the effector. The distance from the target is defined from this point.
  EffectorSelection get forceSource => throw UnimplementedError('Implemented via Physics Worker');
  set forceSource(EffectorSelection value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The linear damping to apply to rigid-bodies.
  double get linearDamping => throw UnimplementedError('Implemented via Physics Worker');
  set linearDamping(double value) => throw UnimplementedError('Implemented via Physics Worker');

}