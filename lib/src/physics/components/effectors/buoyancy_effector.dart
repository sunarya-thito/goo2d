import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Applies forces to simulate buoyancy, fluid-flow and fluid damping.
/// 
/// Equivalent to Unity's `BuoyancyEffector2D`.
class BuoyancyEffector extends Component {
  /// Defines an arbitrary horizontal line that represents the fluid surface level.
  double get surfaceLevel => throw UnimplementedError('Implemented via Physics Worker');
  set surfaceLevel(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A force applied to slow angular movement of any Collider2D in contact with the effector.
  double get angularDamping => throw UnimplementedError('Implemented via Physics Worker');
  set angularDamping(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The magnitude of the force used to similate fluid flow.
  double get flowMagnitude => throw UnimplementedError('Implemented via Physics Worker');
  set flowMagnitude(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The density of the fluid used to calculate the buoyancy forces.
  double get density => throw UnimplementedError('Implemented via Physics Worker');
  set density(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The random variation of the force used to similate fluid flow.
  double get flowVariation => throw UnimplementedError('Implemented via Physics Worker');
  set flowVariation(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A force applied to slow linear movement of any Collider2D in contact with the effector.
  double get linearDamping => throw UnimplementedError('Implemented via Physics Worker');
  set linearDamping(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angle of the force used to similate fluid flow.
  double get flowAngle => throw UnimplementedError('Implemented via Physics Worker');
  set flowAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

}