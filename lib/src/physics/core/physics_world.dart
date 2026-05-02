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

class PhysicsWorld {
  final Map<int, PhysicsBody> bodies = {};
  final Map<int, Joint> joints = {};
  Offset gravity = const Offset(0, 980);
  final List<PhysicsContact> activeContacts = [];
  Iterable<PhysicsShape> get allShapes => bodies.values.expand((b) => b.shapes);
  PhysicsRaycastHit? raycast(
    Offset origin,
    Offset direction,
    double maxDistance,
  ) {
    return raycastWorld(this, origin, direction, maxDistance);
  }

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

class StepResult {
  final List<PhysicsContact> contacts;

  StepResult({required this.contacts});
}
