import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// A base class for all 2D effectors.
/// 
/// Equivalent to Unity's `Effector2D`.
class Effector extends Component {
  /// Should the collider-mask be used or the global collision matrix?
  bool get useColliderMask => throw UnimplementedError('Implemented via Physics Worker');
  set useColliderMask(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The mask used to select specific layers allowed to interact with the effector.
  int get colliderMask => throw UnimplementedError('Implemented via Physics Worker');
  set colliderMask(int value) => throw UnimplementedError('Implemented via Physics Worker');

}