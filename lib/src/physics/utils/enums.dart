// Generated Physics Enums

/// The direction that the capsule sides can extend.
enum CapsuleDirection {
  /// The capsule sides extend vertically.
  vertical,
  /// The capsule sides extend horizontally.
  horizontal
}

/// Indicates what (if any) error was encountered when creating a 2D Collider.
enum ColliderErrorState {
  /// Indicates that no physics shapes were created by the 2D Collider because the state of 2D Collider resulted in vertices too close or an area that is too small for the physics engine to handle.
  noShapes,
  /// Indicates that some physics shapes were not created by the 2D Collider because the state of 2D Collider resulted in vertices too close or an area that is too small for the physics engine to handle.
  removedShapes,
  /// Indicates that no error was encountered, therefore the 2D Collider was created successfully.
  none
}

/// Controls how collisions are detected when a Rigidbody2D moves.
enum CollisionDetectionMode {
  /// When a Rigidbody2D moves, only collisions at the new position are detected.
  discrete,
  /// Ensures that all collisions are detected when a Rigidbody2D moves.
  continuous
}

/// Specifies the composite operation to be used by a Collider2D.
enum CompositeOperation {
  /// Indicates a composite operation that composes geometry using a Boolean AND operation.
  intersect,
  /// Indicates a composite operation that composes geometry using a Boolean OR operation.
  merge,
  /// Indicates that a CompositeCollider2D will not be used i.e. no composite operation will take place.
  none,
  /// Indicates a composite operation that composes geometry using a Boolean NOT operation.
  difference,
  /// Indicates a composite operation that composes geometry using a Boolean XOR operation.
  flip
}

/// The mode used to apply Effector2D forces.
enum EffectorForceMode {
  /// The force is applied inverse-squared relative to a point.
  inverseSquared,
  /// The force is applied inverse-linear relative to a point.
  inverseLinear,
  /// The force is applied at a constant rate.
  constant
}

/// Selects the source and/or target to be used by an Effector2D.
enum EffectorSelection {
  /// The source/target is defined by the Rigidbody2D.
  rigidbody,
  /// The source/target is defined by the Collider2D.
  collider
}

/// Option for how to apply a force using Rigidbody2D.AddForce.
enum ForceMode {
  /// Add an instant force impulse to the rigidbody2D, using its mass.
  impulse,
  /// Add a force to the Rigidbody2D, using its mass.
  force
}

/// Specifies when to generate the Composite Collider geometry.
enum GenerationType {
  /// Sets the Composite Collider geometry to not automatically update when a Collider used by the Composite Collider changes.
  manual,
  /// Sets the Composite Collider geometry to update synchronously immediately when a Collider used by the Composite Collider changes.
  synchronous
}

/// Specifies the type of geometry the Composite Collider generates.
enum GeometryType {
  /// Sets the Composite Collider 2D to generate closed outlines for the merged collider geometry consisting of only edges.
  outlines,
  /// Sets the Composite Collider 2D to generate closed outlines for the merged collider geometry consisting of convex polygon shapes.
  polygons
}

/// Represents the state of a joint limit.
enum JointLimitState {
  /// Represents a state where the joint limit is inactive.
  inactive,
  /// Represents a state where the joint limit is at the specified upper limit.
  upperLimit,
  /// Represents a state where the joint limit is at the specified lower and upper limits (they are identical).
  equalLimits,
  /// Represents a state where the joint limit is at the specified lower limit.
  lowerLimit
}

/// Describes how PhysicsMaterial2D friction and bounciness are combined when two Collider2D come into contact.
enum PhysicsMaterialCombine {
  /// Uses a Geomtric Mean algorithm when combining friction or bounciness.
  mean,
  /// Uses a Maximum algorithm when combining friction or bounciness i.e. the maximum of the two values is used.
  maximum,
  /// Uses a Multiply algorithm when combining friction or bounciness i.e. the product of the two values is used.
  multiply,
  /// Uses a Minimum algorithm when combining friction or bounciness i.e. the minimum of the two values is used.
  minimum,
  /// Uses an Average algorithm when combining friction or bounciness.
  average
}

/// Options for indicate which primitive shape type is used to interpret geometry contained within a PhysicsShape2D object.
enum PhysicsShapeType {
  /// Use a capsule shape to interpret the PhysicsShape2D geometry.
  capsule,
  /// Use multiple edges to interpret the PhysicsShape2D geometry.
  edges,
  /// Use a circle shape to interpret the PhysicsShape2D geometry.
  circle,
  /// Use a convex polygon shape to interpret the PhysicsShape2D geometry.
  polygon
}

/// Interpolation mode for Rigidbody2D objects.
enum RigidbodyInterpolation {
  /// Do not apply any smoothing to the object's movement.
  none,
  /// Smooth movement based on the object's positions in previous frames.
  interpolate,
  /// Smooth an object's movement based on an estimate of its position in the next frame.
  extrapolate
}

/// Settings for a Rigidbody2D's initial sleep state.
enum RigidbodySleepMode {
  /// Rigidbody2D is initially awake.
  startAwake,
  /// Rigidbody2D is initially asleep.
  startAsleep,
  /// Rigidbody2D never automatically sleeps.
  neverSleep
}

/// The physical behaviour type of the Rigidbody2D.
enum RigidbodyType {
  /// Sets the Rigidbody2D to have dynamic behaviour.
  dynamic,
  /// Sets the Rigidbody2D to have static behaviour.
  static,
  /// Sets the Rigidbody2D to have kinematic behaviour.
  kinematic
}

/// A selection of modes that control when Unity executes the 2D physics simulation.
enum SimulationMode {
  /// Use this enumeration to specify to Unity that it should execute the physics simulation immediately after MonoBehaviour.Update.
  update,
  /// Use this enumeration to specify to Unity that it should execute the physics simulation immediately after the MonoBehaviour.FixedUpdate.
  fixedUpdate,
  /// Use this enumeration to specify to Unity that it should execute the physics simulation manually when you call Physics2D.Simulate.
  script
}