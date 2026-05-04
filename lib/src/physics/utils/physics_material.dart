import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Asset type that defines the surface properties of a Collider2D.
/// 
/// Equivalent to Unity's `PhysicsMaterial2D`.
class PhysicsMaterial {
  /// Calculates the effective value used when two Collider2D come into contact with their own PhysicsMaterial2D.
  /// - [valueA]: Friction or bounciness value used by one Collider2D.
  /// - [valueB]: Friction or bounciness value used by another Collider2D.
  /// - [materialCombineA]: The combined mode used by one Collider2D.
  /// - [materialCombineB]: The combined mode used by another Collider2D.
  static double getCombinedValues(double valueA, double valueB, PhysicsMaterialCombine materialCombineA, PhysicsMaterialCombine materialCombineB) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Determines how the effective bounciness is calculated when two Collider2D come into contact.
  PhysicsMaterialCombine get bounceCombine => throw UnimplementedError('Implemented via Physics Worker');
  set bounceCombine(PhysicsMaterialCombine value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Determines how the effective friction is calculated when two Collider2D come into contact.
  PhysicsMaterialCombine get frictionCombine => throw UnimplementedError('Implemented via Physics Worker');
  set frictionCombine(PhysicsMaterialCombine value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Coefficient of friction.
  double get friction => throw UnimplementedError('Implemented via Physics Worker');
  set friction(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Coefficient of restitution.
  double get bounciness => throw UnimplementedError('Implemented via Physics Worker');
  set bounciness(double value) => throw UnimplementedError('Implemented via Physics Worker');

}