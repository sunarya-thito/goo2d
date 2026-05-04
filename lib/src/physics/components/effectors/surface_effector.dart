import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Applies tangent forces along the surfaces of colliders.
/// 
/// Equivalent to Unity's `SurfaceEffector2D`.
class SurfaceEffector extends Component {
  /// The speed variation (from zero to the variation) added to base speed to be applied.
  double get speedVariation => throw UnimplementedError('Implemented via Physics Worker');
  set speedVariation(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The scale of the impulse force applied while attempting to reach the surface speed.
  double get forceScale => throw UnimplementedError('Implemented via Physics Worker');
  set forceScale(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should bounce be used for any contact with the surface?
  bool get useBounce => throw UnimplementedError('Implemented via Physics Worker');
  set useBounce(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The speed to be maintained along the surface.
  double get speed => throw UnimplementedError('Implemented via Physics Worker');
  set speed(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should the impulse force but applied to the contact point?
  bool get useContactForce => throw UnimplementedError('Implemented via Physics Worker');
  set useContactForce(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should friction be used for any contact with the surface?
  bool get useFriction => throw UnimplementedError('Implemented via Physics Worker');
  set useFriction(bool value) => throw UnimplementedError('Implemented via Physics Worker');

}