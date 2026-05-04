import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Applies "platform" behaviour such as one-way collisions etc.
/// 
/// Equivalent to Unity's `PlatformEffector2D`.
class PlatformEffector extends Component {
  /// The rotational offset angle from the local 'up'.
  double get rotationalOffset => throw UnimplementedError('Implemented via Physics Worker');
  set rotationalOffset(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angle of an arc that defines the surface of the platform centered of the local 'up' of the effector.
  double get surfaceArc => throw UnimplementedError('Implemented via Physics Worker');
  set surfaceArc(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Ensures that all contacts controlled by the one-way behaviour act the same.
  bool get useOneWayGrouping => throw UnimplementedError('Implemented via Physics Worker');
  set useOneWayGrouping(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angle of an arc that defines the sides of the platform centered on the local 'left' and 'right' of the effector. Any collision normals within this arc are considered for the 'side' behaviours.
  double get sideArc => throw UnimplementedError('Implemented via Physics Worker');
  set sideArc(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should friction be used on the platform sides?
  bool get useSideFriction => throw UnimplementedError('Implemented via Physics Worker');
  set useSideFriction(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should the one-way collision behaviour be used?
  bool get useOneWay => throw UnimplementedError('Implemented via Physics Worker');
  set useOneWay(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should bounce be used on the platform sides?
  bool get useSideBounce => throw UnimplementedError('Implemented via Physics Worker');
  set useSideBounce(bool value) => throw UnimplementedError('Implemented via Physics Worker');

}