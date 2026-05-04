import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that attempts to keep two Rigidbody2D objects a set distance apart by applying a force between them.
/// 
/// Equivalent to Unity's `SpringJoint2D`.
class SpringJoint extends Component {
  /// Should the distance be calculated automatically?
  bool get autoConfigureDistance => throw UnimplementedError('Implemented via Physics Worker');
  set autoConfigureDistance(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The distance the spring will try to keep between the two objects.
  double get distance => throw UnimplementedError('Implemented via Physics Worker');
  set distance(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The amount by which the spring force is reduced in proportion to the movement speed.
  double get dampingRatio => throw UnimplementedError('Implemented via Physics Worker');
  set dampingRatio(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The frequency at which the spring oscillates around the distance distance between the objects.
  double get frequency => throw UnimplementedError('Implemented via Physics Worker');
  set frequency(double value) => throw UnimplementedError('Implemented via Physics Worker');

}