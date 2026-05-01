/// Defines the physical properties of a collider's surface.
/// 
/// Materials control how objects slide and bounce during physical resolution. 
/// Every [Collider] has an associated [PhysicsMaterial].
/// 
/// ```dart
/// const bouncyMetal = PhysicsMaterial(
///   bounciness: 0.8,
///   friction: 0.1,
/// );
/// ```
class PhysicsMaterial {
  /// The restitution coefficient (0.0 to 1.0+). 
  /// 
  /// A value of 0.0 means no bounce, while 1.0 means a perfect 
  /// elastic collision where no energy is lost.
  final double bounciness;
  
  /// The friction coefficient (0.0 to 1.0+).
  /// 
  /// Higher values cause more resistance when sliding against other surfaces, 
  /// simulating rough materials like sandpaper or rubber.
  final double friction;

  /// Creates a [PhysicsMaterial] with the given properties.
  /// 
  /// * [bounciness]: Energy retention multiplier.
  /// * [friction]: Sliding resistance multiplier.
  const PhysicsMaterial({
    this.bounciness = 0.0,
    this.friction = 0.4,
  });

  /// The default material used when none is specified.
  /// 
  /// This material has medium friction and zero bounciness.
  static const defaultMaterial = PhysicsMaterial();
}
