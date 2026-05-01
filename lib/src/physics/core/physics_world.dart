import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/physics_raycast_hit.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart';
import 'package:goo2d/src/physics/core/world/integrator.dart';
import 'package:goo2d/src/physics/core/world/collision_resolver.dart';
import 'package:goo2d/src/physics/core/world/joint_resolver.dart';
import 'package:goo2d/src/physics/core/world/raycaster.dart';

/// The central engine for physical simulation and collision resolution.
/// 
/// [PhysicsWorld] manages a collection of [PhysicsBody]s and performs 
/// iterative integration to simulate physical movement.
class PhysicsWorld {
  /// The registry of all physical bodies in the world.
  final Map<int, PhysicsBody> bodies = {};
  
  /// The registry of all physical joints in the world.
  final Map<int, Joint> joints = {};

  /// Global acceleration vector applied to all dynamic bodies.
  Offset gravity = const Offset(0, 980);

  /// Contacts detected and resolved in the current simulation step.
  final List<PhysicsContact> activeContacts = [];

  /// Flattens the shape lists of all registered bodies into a single iterable.
  Iterable<PhysicsShape> get allShapes => bodies.values.expand((b) => b.shapes);

  /// Performs a linear spatial query to find the first shape hit by a ray.
  PhysicsRaycastHit? raycast(Offset origin, Offset direction, double maxDistance) {
    return raycastWorld(this, origin, direction, maxDistance);
  }

  /// Performs a single simulation step.
  StepResult step(double dt) {
    activeContacts.clear();

    // 1. Integration
    integrateBodies(bodies, gravity, dt);

    // 2. Collision Detection & Resolution
    resolveWorldCollisions(this, dt);

    // 3. Joint Resolution
    resolveJointConstraints(joints, bodies, dt);

    return StepResult(contacts: List.from(activeContacts));
  }
}

/// Result of a single simulation step.
class StepResult {
  /// All active contacts resolved during the step.
  final List<PhysicsContact> contacts;

  StepResult({required this.contacts});
}
