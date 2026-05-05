import 'package:goo2d/goo2d.dart';

/// Asset type that defines the surface properties of a Collider2D.
///
/// Equivalent to Unity's `PhysicsMaterial2D`.
class PhysicsMaterial {
  PhysicsMaterial({
    this.friction = 0.4,
    this.bounciness = 0.0,
    this.frictionCombine = PhysicsMaterialCombine.average,
    this.bounceCombine = PhysicsMaterialCombine.average,
  });

  /// Determines how the effective bounciness is calculated when two Collider2D come into contact.
  PhysicsMaterialCombine bounceCombine;

  /// Determines how the effective friction is calculated when two Collider2D come into contact.
  PhysicsMaterialCombine frictionCombine;

  /// Coefficient of friction.
  double friction;

  /// Coefficient of restitution.
  double bounciness;

  /// Calculates the effective value used when two Collider2D come into contact.
  static double getCombinedValues(double valueA, double valueB, PhysicsMaterialCombine materialCombineA, PhysicsMaterialCombine materialCombineB) {
    final mode = materialCombineA.index >= materialCombineB.index ? materialCombineA : materialCombineB;
    return switch (mode) {
      PhysicsMaterialCombine.minimum => valueA < valueB ? valueA : valueB,
      PhysicsMaterialCombine.multiply => valueA * valueB,
      PhysicsMaterialCombine.maximum => valueA > valueB ? valueA : valueB,
      PhysicsMaterialCombine.mean => (valueA + valueB) / 2,
      _ => (valueA + valueB) / 2,
    };
  }
}
