import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that keeps two Rigidbody2D objects a fixed distance apart.
/// 
/// Equivalent to Unity's `DistanceJoint2D`.
class DistanceJoint extends Component {
  /// Should the distance be calculated automatically?
  bool get autoConfigureDistance => throw UnimplementedError('Implemented via Physics Worker');
  set autoConfigureDistance(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Whether to maintain a maximum distance only or not. If not then the absolute distance will be maintained instead.
  bool get maxDistanceOnly => throw UnimplementedError('Implemented via Physics Worker');
  set maxDistanceOnly(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The distance separating the two ends of the joint.
  double get distance => throw UnimplementedError('Implemented via Physics Worker');
  set distance(double value) => throw UnimplementedError('Implemented via Physics Worker');

}