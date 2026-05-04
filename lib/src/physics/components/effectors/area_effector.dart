import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Applies forces within an area.
/// 
/// Equivalent to Unity's `AreaEffector2D`.
class AreaEffector extends Component {
  /// The magnitude of the force to be applied.
  double get forceMagnitude => throw UnimplementedError('Implemented via Physics Worker');
  set forceMagnitude(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The variation of the magnitude of the force to be applied.
  double get forceVariation => throw UnimplementedError('Implemented via Physics Worker');
  set forceVariation(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The target for where the effector applies any force.
  EffectorSelection get forceTarget => throw UnimplementedError('Implemented via Physics Worker');
  set forceTarget(EffectorSelection value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should the forceAngle use global space?
  bool get useGlobalAngle => throw UnimplementedError('Implemented via Physics Worker');
  set useGlobalAngle(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angular damping to apply to rigid-bodies.
  double get angularDamping => throw UnimplementedError('Implemented via Physics Worker');
  set angularDamping(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The linear damping to apply to rigid-bodies.
  double get linearDamping => throw UnimplementedError('Implemented via Physics Worker');
  set linearDamping(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angle of the force to be applied.
  double get forceAngle => throw UnimplementedError('Implemented via Physics Worker');
  set forceAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

}