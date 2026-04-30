import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// Represents a physical object in the [PhysicsWorld].
/// 
/// A [PhysicsBody] holds physical properties like mass, velocity, and 
/// forces, and contains one or more [PhysicsShape]s that define its volume. 
/// It is the primary unit of simulation in the engine's internal physics.
/// 
/// ```dart
/// final body = PhysicsBody(id: 1, type: 0);
/// body.position = Offset(100, 100);
/// ```
class PhysicsBody {
  /// Unique identifier for this body.
  /// 
  /// Used by the [PhysicsSystem] to track bodies across frames and 
  /// synchronize their state with the worker.
  final int id;
  /// The type of body (0: dynamic, 1: kinematic, 2: static).
  /// 
  /// 0: Dynamic bodies respond to forces and gravity.
  /// 1: Kinematic bodies move only via velocity.
  /// 2: Static bodies are immovable.
  /// 
  /// The type determines which integration path the [PhysicsWorld] 
  /// uses for the body.
  int type; // 0: dynamic, 1: kinematic, 2: static

  /// World-space position.
  /// 
  /// Represents the center of mass of the body. Updated by the 
  /// integrator every step based on velocity and forces.
  Offset position = Offset.zero;
  /// Rotation in radians.
  /// 
  /// The orientation of the body in world space. Affects the 
  /// orientation of all attached [PhysicsShape]s.
  double rotation = 0.0;
  /// Linear velocity in pixels per second.
  /// 
  /// The current speed and direction of the body. Subject to 
  /// [drag] and external impulses.
  Offset velocity = Offset.zero;
  /// Angular velocity in radians per second.
  /// 
  /// The current rotational speed. Subject to [angularDrag] and 
  /// torque-induced acceleration.
  double angularVelocity = 0.0;

  /// The mass of the body.
  /// 
  /// Determines resistance to linear acceleration. Must be positive 
  /// for dynamic bodies to avoid infinite acceleration.
  double mass = 1.0;
  /// The inverse mass (1/mass). Used to optimize integration.
  /// 
  /// Cached to avoid division in the hot path of the simulation loop.
  double invMass = 1.0;
  /// The moment of inertia.
  /// 
  /// Determines resistance to rotational acceleration based on mass 
  /// distribution relative to the center.
  double inertia = 1.0;
  /// The inverse moment of inertia (1/inertia).
  /// 
  /// Used for rotational integration. Setting this to 0.0 effectively 
  /// freezes rotation.
  double invInertia = 1.0;

  /// Multiplier for the global gravity vector.
  /// 
  /// Allows individual bodies to fall faster or slower than the 
  /// world's base gravity setting.
  double gravityScale = 1.0;
  /// Linear damping coefficient.
  /// 
  /// Simulates air resistance or friction. Gradually reduces linear 
  /// velocity over time.
  double drag = 0.0;
  /// Angular damping coefficient.
  /// 
  /// Simulates rotational resistance. Gradually reduces angular 
  /// velocity over time.
  double angularDrag = 0.05;

  bool _freezeRotation = false;
  /// Whether the body's rotation is locked.
  /// 
  /// When true, the body will not rotate regardless of forces or impulses applied.
  bool get freezeRotation => _freezeRotation;

  /// Sets whether the body's rotation is frozen.
  /// 
  /// Updates the internal inertia state to reflect the new rotation constraint.
  /// 
  /// * [value]: True to lock rotation, false to allow it.
  set freezeRotation(bool value) {
    _freezeRotation = value;
    setInertia(inertia);
  }

  /// Accumulated linear force for the current step.
  /// 
  /// Forces are reset at the end of each [integrate] call.
  Offset force = Offset.zero;
  /// Accumulated torque for the current step.
  /// 
  /// Torques affect angular acceleration and are reset every step.
  double torque = 0.0;

  /// The list of geometric shapes attached to this body.
  /// 
  /// Each shape defines a portion of the body's physical volume and 
  /// material properties like friction and bounciness.
  final List<PhysicsShape> shapes = [];

  /// Creates a [PhysicsBody] with a unique [id].
  /// 
  /// * [id]: The unique identifier for this body.
  /// * [type]: The body type (dynamic, kinematic, or static).
  PhysicsBody({required this.id, this.type = 0});

  /// Adds a [force] to be applied during the next integration step.
  /// 
  /// Only dynamic bodies respond to force accumulation.
  /// 
  /// * [f]: The force vector to apply.
  void applyForce(Offset f) {
    if (type != 0) return;
    force += f;
  }

  /// Applies an instantaneous change in linear velocity.
  /// 
  /// Impulses are applied directly to the velocity based on the inverse mass.
  /// 
  /// * [j]: The impulse vector to apply.
  void applyImpulse(Offset j) {
    if (type != 0) return;
    velocity += j * invMass;
  }

  /// Adds [torque] to be applied during the next integration step.
  /// 
  /// Only dynamic bodies respond to torque accumulation.
  /// 
  /// * [t]: The torque value to apply.
  void applyTorque(double t) {
    if (type != 0) return;
    torque += t;
  }

  /// Applies an instantaneous change in angular velocity.
  /// 
  /// The rotational velocity is modified based on the impulse and 
  /// the current [invInertia].
  /// 
  /// * [j]: The angular impulse to apply.
  void applyAngularImpulse(double j) {
    if (type != 0) return;
    angularVelocity += j * invInertia;
  }

  /// Sets the [mass] and updates the [invMass].
  /// 
  /// Providing a mass of 0.0 effectively makes the body's mass infinite, 
  /// preventing linear acceleration.
  /// 
  /// * [m]: The new mass value.
  void setMass(double m) {
    mass = m;
    invMass = m > 0 ? 1.0 / m : 0.0;
  }

  /// Sets the rotational [inertia] and updates the [invInertia].
  /// 
  /// If [freezeRotation] is active, the [invInertia] will be set to 0.0 
  /// regardless of the input value.
  /// 
  /// * [i]: The new moment of inertia.
  void setInertia(double i) {
    inertia = i;
    invInertia = i > 0 && !freezeRotation ? 1.0 / i : 0.0;
  }

  /// Advances the body's state by a single time step [dt].
  /// 
  /// This method applies forces, gravity, and drag to update velocities, 
  /// which are then used to increment [position] and [rotation].
  /// 
  /// * [dt]: The duration of the simulation step.
  /// * [gravity]: The global gravity vector to apply.
  void integrate(double dt, Offset gravity) {
    if (type != 0) return; // Only dynamic bodies integrate

    // Apply accumulated forces
    velocity += (force * invMass + gravity * gravityScale) * dt;
    angularVelocity += torque * invInertia * dt;

    // Apply drag
    velocity *= (1.0 - drag * dt);
    angularVelocity *= (1.0 - angularDrag * dt);

    // Apply velocity
    position += velocity * dt;
    rotation += angularVelocity * dt;

    // Reset forces
    force = Offset.zero;
    torque = 0.0;
  }
}

/// Base class for all geometric shapes used in collision detection.
/// 
/// [PhysicsShape] defines the volume of a [PhysicsBody] and provides 
/// the mathematical basis for intersection and contact resolution.
/// 
/// ```dart
/// final circle = PhysicsCircle(id: 1, radius: 10.0);
/// body.addShape(circle);
/// ```
abstract class PhysicsShape {
  /// Unique identifier for this shape.
  /// 
  /// Used to map collision events back to specific engine colliders.
  int id = 0;
  /// The ID of the parent body.
  /// 
  /// Allows the collision resolver to fetch the associated [PhysicsBody] 
  /// for mass and velocity data.
  int bodyId = 0;
  /// The position of the shape relative to the body's center.
  /// 
  /// Used for compound bodies where multiple shapes are offset from 
  /// the main transform.
  Offset localOffset = Offset.zero;
  /// The rotation of the shape relative to the body's orientation.
  /// 
  /// Allows for shapes to be tilted within a larger physical object.
  double localRotation = 0.0;
  /// Whether the shape is a trigger.
  /// 
  /// Triggers detect overlaps but do not generate physical resolution 
  /// forces (they are "ghost" objects).
  bool isTrigger = false;
  /// The restitution coefficient (bounce).
  /// 
  /// Determines how much energy is retained during a collision.
  double bounciness = 0.0;
  /// The friction coefficient.
  /// 
  /// Determines the resistance to sliding against other surfaces.
  double friction = 0.4;

  /// The [PhysicsBody] this shape is currently attached to.
  /// 
  /// Providing a body link allows the shape to participate in the 
  /// physical simulation and receive transforms.
  PhysicsBody? _body;
  
  /// Access the attached body.
  /// 
  /// Returns null if the shape is not currently part of a body.
  PhysicsBody? get body => _body;
  
  /// Sets the parent body.
  /// 
  /// Handles registration and unregistration from the body's shape list.
  /// 
  /// * [value]: The new parent body or null to detach.
  set body(PhysicsBody? value) {
    if (_body == value) return;
    _body?.shapes.remove(this);
    _body = value;
    if (value != null) {
      value.shapes.add(this);
      bodyId = value.id;
    }
  }

  /// Creates a new [PhysicsShape] instance.
  /// 
  /// Initializes the base physical properties with default values.
  PhysicsShape();
}

/// A specialized rectangular polygon shape.
/// 
/// [PhysicsBox] is a convenience for defining rectangular collision 
/// boundaries. It is often used for floors, walls, or boxy characters.
/// 
/// ```dart
/// final box = PhysicsBox(100, 50);
/// ```
class PhysicsBox extends PhysicsShape {
  /// The width and height dimensions of the box.
  /// 
  /// Used to calculate intersection bounds during the collision step.
  final Size size;

  /// Creates a [PhysicsBox] with specific [w]idth and [h]eight.
  /// 
  /// * [w]: The width in pixels.
  /// * [h]: The height in pixels.
  PhysicsBox(double w, double h) : size = Size(w, h);
}

/// A circular geometric shape for collision detection.
/// 
/// Circles are the fastest shapes to resolve as they only require 
/// a radius comparison. Related to [PhysicsWorld].
/// 
/// ```dart
/// final circle = PhysicsCircle(10.0);
/// ```
class PhysicsCircle extends PhysicsShape {
  /// The radius of the circle shape.
  /// 
  /// Defines the distance from the center to the collision boundary.
  final double radius;

  /// Creates a [PhysicsCircle] with a specific [radius].
  /// 
  /// * [radius]: The radius in pixels.
  PhysicsCircle(this.radius);
}

/// A capsule shape consisting of a cylinder with two hemispherical ends.
/// 
/// Capsules are excellent for humanoids as they prevent "snagging" 
/// on corner edges. Related to [PhysicsWorld].
/// 
/// ```dart
/// final capsule = PhysicsCapsule(10.0, 40.0, true);
/// ```
class PhysicsCapsule extends PhysicsShape {
  /// The radius of the capsule ends.
  /// 
  /// Determines the thickness of the capsule body.
  final double radius;

  /// The total height of the capsule.
  /// 
  /// Includes the space occupied by the hemispherical caps.
  final double height;

  /// Whether the capsule is oriented vertically.
  /// 
  /// Determines the axis along which the cylinder is stretched.
  final bool isVertical;

  /// Creates a [PhysicsCapsule] with given dimensions and orientation.
  /// 
  /// * [radius]: The thickness radius.
  /// * [height]: The total length.
  /// * [isVertical]: Orientation flag.
  PhysicsCapsule(this.radius, this.height, this.isVertical);
}

/// A convex polygonal shape defined by a set of vertices.
/// 
/// Polygons provide the most flexibility for custom shapes. Related to [PhysicsWorld].
/// 
/// ```dart
/// final poly = PhysicsPolygon([Offset(0,0), Offset(10,0), Offset(5,10)]);
/// ```
class PhysicsPolygon extends PhysicsShape {
  /// The local vertices of the polygon.
  /// 
  /// These points are relative to the shape's [localOffset].
  final List<Offset> vertices;

  /// Creates a [PhysicsPolygon] from a list of [vertices].
  /// 
  /// * [vertices]: The points defining the convex shape.
  PhysicsPolygon(this.vertices);
}

/// Data returned from a physics raycast operation.
/// 
/// Contains information about where and how a ray intersected 
/// with a [PhysicsShape] in the world. Related to [PhysicsWorld.raycast].
/// 
/// ```dart
/// final hit = world.raycast(origin, dir, 100);
/// if (hit != null) print(hit.point);
/// ```
class PhysicsRaycastHit {
  /// The ID of the shape that was hit.
  /// 
  /// Allows identification of the specific object the ray intersected.
  final int shapeId;

  /// The world-space point of intersection.
  /// 
  /// Useful for positioning impact effects or particles.
  final Offset point;

  /// The surface normal at the point of intersection.
  /// 
  /// Used for calculating reflection vectors or aligning decals.
  final Offset normal;

  /// The distance from the ray origin to the intersection point.
  /// 
  /// Helpful for sorting hits by proximity.
  final double distance;

  /// The distance expressed as a fraction of the ray's maximum length.
  /// 
  /// Range is [0.0, 1.0].
  final double fraction;

  /// Creates a [PhysicsRaycastHit] with intersection details.
  /// 
  /// * [shapeId]: ID of the intersected shape.
  /// * [point]: World-space hit position.
  /// * [normal]: Surface normal at hit.
  /// * [distance]: Distance from origin.
  /// * [fraction]: Percentage of ray length.
  PhysicsRaycastHit({
    required this.shapeId,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}

/// The central engine for physical simulation and collision resolution.
/// 
/// [PhysicsWorld] manages a collection of [PhysicsBody]s and performs 
/// iterative integration to simulate physical movement. It is the core 
/// component used by the physics worker Isolate.
/// 
/// ```dart
/// final world = PhysicsWorld();
/// world.step(1 / 60);
/// ```
class PhysicsWorld {
  /// The registry of all physical bodies in the world.
  /// 
  /// Bodies are indexed by their unique integer ID for fast lookup 
  /// during synchronization and simulation steps.
  final Map<int, PhysicsBody> bodies = {};

  /// Helper to get all shapes across all bodies.
  /// 
  /// Flattens the shape lists of all registered bodies into a single iterable.
  Iterable<PhysicsShape> get allShapes => bodies.values.expand((b) => b.shapes);
  /// The global acceleration vector applied to all dynamic bodies.
  /// 
  /// Represents world forces like gravity. Defaults to 980 pixels/s^2 
  /// downwards (standard Earth gravity scaled for pixels).
  Offset gravity = const Offset(0, 980); // Default gravity (pixels/s^2)

  /// Contacts detected in the current step.
  /// Contacts detected and resolved in the current simulation step.
  /// 
  /// This list is cleared at the start of every [step] and populated during 
  /// the collision detection phase.
  final List<PhysicsContact> activeContacts = [];

  /// Performs a linear spatial query to find the first shape hit by a ray.
  /// 
  /// Iterates through all shapes in the world and calculates intersections. 
  /// Returns the closest hit or null if nothing was intersected.
  /// 
  /// * [origin]: The starting point of the ray in world space.
  /// * [direction]: The normalized direction vector of the ray.
  /// * [maxDistance]: The maximum length of the ray to check.
  PhysicsRaycastHit? raycast(
    Offset origin,
    Offset direction,
    double maxDistance,
  ) {
    PhysicsRaycastHit? closestHit;

    for (final shape in allShapes) {
      final body = bodies[shape.bodyId]!;
      PhysicsRaycastHit? hit;

      if (shape is PhysicsCircle) {
        hit = _raycastCircle(shape, body, origin, direction, maxDistance);
      } else if (shape is PhysicsBox) {
        hit = _raycastPolygon(
          _boxToPolygon(shape, body),
          body,
          origin,
          direction,
          maxDistance,
        );
      } else if (shape is PhysicsPolygon) {
        hit = _raycastPolygon(shape, body, origin, direction, maxDistance);
      }

      if (hit != null) {
        if (closestHit == null || hit.distance < closestHit.distance) {
          closestHit = hit;
        }
      }
    }

    return closestHit;
  }

  PhysicsRaycastHit? _raycastCircle(
    PhysicsCircle circle,
    PhysicsBody body,
    Offset origin,
    Offset direction,
    double maxDistance,
  ) {
    final center = _getTransformedPoint(circle.localOffset, body);
    final L = center - origin;
    final tca = L.dx * direction.dx + L.dy * direction.dy;
    if (tca < 0) return null;

    final d2 = L.dx * L.dx + L.dy * L.dy - tca * tca;
    final r2 = circle.radius * circle.radius;
    if (d2 > r2) return null;

    final thc = math.sqrt(r2 - d2);
    final t0 = tca - thc;

    if (t0 < 0 || t0 > maxDistance) return null;

    final point = origin + direction * t0;
    final normal = (point - center) / circle.radius;

    return PhysicsRaycastHit(
      shapeId: circle.id,
      point: point,
      normal: normal,
      distance: t0,
      fraction: t0 / maxDistance,
    );
  }

  PhysicsRaycastHit? _raycastPolygon(
    PhysicsPolygon poly,
    PhysicsBody body,
    Offset origin,
    Offset direction,
    double maxDistance,
  ) {
    final verts = _getTransformedVertices(poly, body);
    double minT = double.infinity;
    Offset bestNormal = Offset.zero;

    for (int i = 0; i < verts.length; i++) {
      final p1 = verts[i];
      final p2 = verts[(i + 1) % verts.length];

      // Ray-Segment intersection
      final v1 = origin - p1;
      final v2 = p2 - p1;
      final v3 = Offset(-direction.dy, direction.dx);

      final dot = v2.dx * v3.dx + v2.dy * v3.dy;
      if (dot.abs() < 0.000001) continue;

      final t1 = (v2.dx * v1.dy - v2.dy * v1.dx) / dot;
      final t2 = (v1.dx * v3.dx + v1.dy * v3.dy) / dot;

      if (t1 >= 0 && t1 <= maxDistance && t2 >= 0 && t2 <= 1) {
        if (t1 < minT) {
          minT = t1;
          final edge = p2 - p1;
          final dist = edge.distance;
          if (dist > 0.000001) {
            bestNormal = Offset(-edge.dy, edge.dx) / dist;
            // Ensure normal points away from ray
            if (bestNormal.dx * direction.dx + bestNormal.dy * direction.dy > 0) {
              bestNormal *= -1.0;
            }
          }
        }
      }
    }

    if (minT == double.infinity) return null;

    return PhysicsRaycastHit(
      shapeId: poly.id,
      point: origin + direction * minT,
      normal: bestNormal,
      distance: minT,
      fraction: minT / maxDistance,
    );
  }

  /// Performs a single simulation step.
  /// 
  /// This updates the positions and velocities of all bodies based on 
  /// forces, gravity, and collisions. Returns a [StepResult].
  /// 
  /// * [dt]: The fixed time step in seconds.
  StepResult step(double dt) {
    activeContacts.clear();

    // 1. Integration
    for (final body in bodies.values) {
      body.integrate(dt, gravity);
    }

    // 2. Collision Detection & Resolution
    _resolveCollisions(dt);

    return StepResult(contacts: List.from(activeContacts));
  }

  void _resolveCollisions(double dt) {
    final allShapesList = allShapes.toList();
    for (int i = 0; i < allShapesList.length; i++) {
      for (int j = i + 1; j < allShapesList.length; j++) {
        final sA = allShapesList[i];
        final sB = allShapesList[j];

        final bA = bodies[sA.bodyId]!;
        final bB = bodies[sB.bodyId]!;

        // Check if we should skip this pair
        // We only resolve physical collisions if at least one body is dynamic.
        // However, we still want to detect TRIGGERS between any bodies (except static-static).
        // Allow detection between all non-static bodies.
        // Even if both are kinematic, we want to detect the overlap for events.
        // Static-Static never collide.
        if (bA.type == 2 && bB.type == 2) continue;
        if (bA == bB) continue; // Same body

        final manifold = _checkCollision(sA, bA, sB, bB);
        if (manifold != null) {
          double impulseValue = 0.0;
          if (!sA.isTrigger && !sB.isTrigger) {
            impulseValue = _applyImpulse(bA, bB, sA, sB, manifold);
          }

          activeContacts.add(
            PhysicsContact(
              shapeAId: sA.id,
              shapeBId: sB.id,
              manifold: manifold,
              impulse: impulseValue,
            ),
          );
        }
      }
    }
  }

  ContactManifold? _checkCollision(
    PhysicsShape sA,
    PhysicsBody bA,
    PhysicsShape sB,
    PhysicsBody bB,
  ) {
    if (sA is PhysicsCircle && sB is PhysicsCircle) {
      return _checkCircleCircle(sA, bA, sB, bB);
    } else if (sA is PhysicsBox && sB is PhysicsBox) {
      return _checkBoxBox(sA, bA, sB, bB);
    } else if (sA is PhysicsCircle && sB is PhysicsBox) {
      return _checkCircleBox(sA, bA, sB, bB);
    } else if (sA is PhysicsBox && sB is PhysicsCircle) {
      return _flipManifold(_checkCircleBox(sB, bB, sA, bA));
    } else if (sA is PhysicsPolygon && sB is PhysicsPolygon) {
      return _checkPolygonPolygon(sA, bA, sB, bB);
    } else if (sA is PhysicsCircle && sB is PhysicsPolygon) {
      return _checkCirclePolygon(sA, bA, sB, bB);
    } else if (sA is PhysicsPolygon && sB is PhysicsCircle) {
      return _flipManifold(_checkCirclePolygon(sB, bB, sA, bA));
    } else if (sA is PhysicsBox && sB is PhysicsPolygon) {
      return _checkPolygonPolygon(_boxToPolygon(sA, bA), bA, sB, bB);
    } else if (sA is PhysicsPolygon && sB is PhysicsBox) {
      return _checkPolygonPolygon(sA, bA, _boxToPolygon(sB, bB), bB);
    }
    return null;
  }

  ContactManifold? _flipManifold(ContactManifold? manifold) {
    if (manifold == null) return null;
    return ContactManifold(
      normal: manifold.normal * -1.0,
      depth: manifold.depth,
      contactPoint: manifold.contactPoint,
    );
  }

  PhysicsPolygon _boxToPolygon(PhysicsBox box, PhysicsBody body) {
    final halfW = box.size.width / 2;
    final halfH = box.size.height / 2;
    return PhysicsPolygon([
        Offset(-halfW, -halfH),
        Offset(halfW, -halfH),
        Offset(halfW, halfH),
        Offset(-halfW, halfH),
      ])
      ..id = box.id
      ..bodyId = box.bodyId
      ..localOffset = box.localOffset;
  }

  ContactManifold? _checkPolygonPolygon(
    PhysicsPolygon sA,
    PhysicsBody bA,
    PhysicsPolygon sB,
    PhysicsBody bB,
  ) {
    final vertsA = _getTransformedVertices(sA, bA);
    final vertsB = _getTransformedVertices(sB, bB);

    double minOverlap = double.infinity;
    Offset bestAxis = Offset.zero;

    final axes = [..._getPolygonAxes(vertsA), ..._getPolygonAxes(vertsB)];
    for (final axis in axes) {
      final projA = _projectPolygon(vertsA, axis);
      final projB = _projectPolygon(vertsB, axis);

      final overlap =
          math.min(projA[1], projB[1]) - math.max(projA[0], projB[0]);
      if (overlap <= 0) return null;

      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis = axis;
      }
    }

    Offset normal = bestAxis;
    final centerA = _getPolygonCenter(vertsA);
    final centerB = _getPolygonCenter(vertsB);
    if ((centerB - centerA).dx * normal.dx +
            (centerB - centerA).dy * normal.dy <
        0) {
      normal *= -1.0;
    }

    return ContactManifold(
      normal: normal,
      depth: minOverlap,
      contactPoint: centerA + normal * (minOverlap / 2), // Rough approximation
    );
  }

  ContactManifold? _checkCirclePolygon(
    PhysicsCircle sA,
    PhysicsBody bA,
    PhysicsPolygon sB,
    PhysicsBody bB,
  ) {
    final center = _getTransformedPoint(sA.localOffset, bA);
    final verts = _getTransformedVertices(sB, bB);

    double minOverlap = double.infinity;
    Offset bestAxis = Offset.zero;

    final axes = _getPolygonAxes(verts);
    // Also check axis from closest vertex to circle center
    final closestVert = _getClosestVertex(center, verts);
    final circleAxis = (center - closestVert);
    if (circleAxis.distanceSquared > 0) {
      axes.add(circleAxis / circleAxis.distance);
    }

    for (final axis in axes) {
      final projA = [
        center.dx * axis.dx + center.dy * axis.dy - sA.radius,
        center.dx * axis.dx + center.dy * axis.dy + sA.radius,
      ];
      final projB = _projectPolygon(verts, axis);

      final overlap =
          math.min(projA[1], projB[1]) - math.max(projA[0], projB[0]);
      if (overlap <= 0) return null;

      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis = axis;
      }
    }

    Offset normal = bestAxis;
    final centerB = _getPolygonCenter(verts);
    if ((centerB - center).dx * normal.dx + (centerB - center).dy * normal.dy <
        0) {
      normal *= -1.0;
    }

    return ContactManifold(
      normal: normal,
      depth: minOverlap,
      contactPoint: center + normal * (sA.radius - minOverlap / 2),
    );
  }

  List<Offset> _getTransformedVertices(PhysicsPolygon poly, PhysicsBody body) {
    final cos = math.cos(body.rotation);
    final sin = math.sin(body.rotation);
    return poly.vertices.map((v) {
      final local = v + poly.localOffset;
      return body.position +
          Offset(
            local.dx * cos - local.dy * sin,
            local.dx * sin + local.dy * cos,
          );
    }).toList();
  }

  List<Offset> _getPolygonAxes(List<Offset> verts) {
    final axes = <Offset>[];
    for (int i = 0; i < verts.length; i++) {
      final p1 = verts[i];
      final p2 = verts[(i + 1) % verts.length];
      final edge = p2 - p1;
      final normal = Offset(-edge.dy, edge.dx);
      if (normal.distanceSquared > 0) {
        axes.add(normal / normal.distance);
      }
    }
    return axes;
  }

  List<double> _projectPolygon(List<Offset> verts, Offset axis) {
    double min = double.infinity;
    double max = -double.infinity;
    for (final v in verts) {
      final proj = v.dx * axis.dx + v.dy * axis.dy;
      if (proj < min) min = proj;
      if (proj > max) max = proj;
    }
    return [min, max];
  }

  Offset _getPolygonCenter(List<Offset> verts) {
    Offset sum = Offset.zero;
    for (final v in verts) {
      sum += v;
    }
    return sum / verts.length.toDouble();
  }

  Offset _getClosestVertex(Offset point, List<Offset> verts) {
    double minDist = double.infinity;
    Offset closest = verts[0];
    for (final v in verts) {
      final dist = (point - v).distanceSquared;
      if (dist < minDist) {
        minDist = dist;
        closest = v;
      }
    }
    return closest;
  }

  ContactManifold? _checkCircleCircle(
    PhysicsCircle sA,
    PhysicsBody bA,
    PhysicsCircle sB,
    PhysicsBody bB,
  ) {
    final posA = _getTransformedPoint(sA.localOffset, bA);
    final posB = _getTransformedPoint(sB.localOffset, bB);
    final delta = posB - posA;
    final distSq = delta.distanceSquared;
    final radiusSum = sA.radius + sB.radius;

    if (distSq > radiusSum * radiusSum) return null;

    final dist = math.sqrt(distSq);
    final normal = dist > 0 ? delta / dist : const Offset(0, 1);
    final depth = radiusSum - dist;

    return ContactManifold(
      normal: normal,
      depth: depth,
      contactPoint: posA + normal * sA.radius,
    );
  }

  ContactManifold? _checkBoxBox(
    PhysicsBox sA,
    PhysicsBody bA,
    PhysicsBox sB,
    PhysicsBody bB,
  ) {
    final posA = _getTransformedPoint(sA.localOffset, bA);
    final posB = _getTransformedPoint(sB.localOffset, bB);

    // Get axes for box A
    final axesA = _getBoxAxes(bA.rotation);
    final axesB = _getBoxAxes(bB.rotation);

    final halfA = [sA.size.width / 2, sA.size.height / 2];
    final halfB = [sB.size.width / 2, sB.size.height / 2];

    double minOverlap = double.infinity;
    Offset bestAxis = Offset.zero;

    final axes = [...axesA, ...axesB];
    for (final axis in axes) {
      final overlap = _getOverlap(posA, axesA, halfA, posB, axesB, halfB, axis);
      if (overlap <= 0) return null;
      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis = axis;
      }
    }

    // Ensure normal points from A to B
    Offset normal = bestAxis;
    if ((posB - posA).dx * normal.dx + (posB - posA).dy * normal.dy < 0) {
      normal *= -1.0;
    }

    return ContactManifold(
      normal: normal,
      depth: minOverlap,
      contactPoint:
          posA +
          normal * (halfA[0] + minOverlap / 2), // Simplified contact point
    );
  }

  List<Offset> _getBoxAxes(double rotation) {
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    return [Offset(cos, sin), Offset(-sin, cos)];
  }

  double _getOverlap(
    Offset posA,
    List<Offset> axesA,
    List<double> halfA,
    Offset posB,
    List<Offset> axesB,
    List<double> halfB,
    Offset axis,
  ) {
    final projA = _projectBox(posA, axesA, halfA, axis);
    final projB = _projectBox(posB, axesB, halfB, axis);

    final minA = projA[0];
    final maxA = projA[1];
    final minB = projB[0];
    final maxB = projB[1];

    if (maxA < minB || maxB < minA) return 0;
    return math.min(maxA, maxB) - math.max(minA, minB);
  }

  List<double> _projectBox(
    Offset pos,
    List<Offset> axes,
    List<double> half,
    Offset axis,
  ) {
    final centerProj = pos.dx * axis.dx + pos.dy * axis.dy;
    final r =
        half[0] * (axes[0].dx * axis.dx + axes[0].dy * axis.dy).abs() +
        half[1] * (axes[1].dx * axis.dx + axes[1].dy * axis.dy).abs();
    return [centerProj - r, centerProj + r];
  }

  ContactManifold? _checkCircleBox(
    PhysicsCircle sA,
    PhysicsBody bA,
    PhysicsBox sB,
    PhysicsBody bB,
  ) {
    final center = _getTransformedPoint(sA.localOffset, bA);
    final boxPos = _getTransformedPoint(sB.localOffset, bB);

    // Transform circle center to box local space
    final relative = center - boxPos;
    final cos = math.cos(-bB.rotation);
    final sin = math.sin(-bB.rotation);
    final localCenter = Offset(
      relative.dx * cos - relative.dy * sin,
      relative.dx * sin + relative.dy * cos,
    );

    final half = Offset(sB.size.width / 2, sB.size.height / 2);

    final closest = Offset(
      localCenter.dx.clamp(-half.dx, half.dx),
      localCenter.dy.clamp(-half.dy, half.dy),
    );

    final localDelta = closest - localCenter;
    final distSq = localDelta.distanceSquared;

    if (distSq > sA.radius * sA.radius && distSq > 0) return null;

    // Transform normal back to world space
    Offset worldNormal;
    double depth;
    Offset contactPoint;

    if (distSq == 0) {
      // Inside box
      final dX = localCenter.dx.abs() - half.dx;
      final dY = localCenter.dy.abs() - half.dy;
      if (dX > dY) {
        final nx = localCenter.dx > 0 ? 1.0 : -1.0;
        worldNormal = Offset(
          nx * math.cos(bB.rotation),
          nx * math.sin(bB.rotation),
        );
        depth = sA.radius - dX;
      } else {
        final ny = localCenter.dy > 0 ? 1.0 : -1.0;
        worldNormal = Offset(
          -ny * math.sin(bB.rotation),
          ny * math.cos(bB.rotation),
        );
        depth = sA.radius - dY;
      }
      contactPoint = center + worldNormal * sA.radius;
    } else {
      final dist = math.sqrt(distSq);
      final localNormal = localDelta / dist;
      worldNormal = Offset(
        localNormal.dx * math.cos(bB.rotation) -
            localNormal.dy * math.sin(bB.rotation),
        localNormal.dx * math.sin(bB.rotation) +
            localNormal.dy * math.cos(bB.rotation),
      );
      depth = sA.radius - dist;
      contactPoint =
          boxPos +
          Offset(
            closest.dx * math.cos(bB.rotation) -
                closest.dy * math.sin(bB.rotation),
            closest.dx * math.sin(bB.rotation) +
                closest.dy * math.cos(bB.rotation),
          );
    }

    return ContactManifold(
      normal: worldNormal * -1.0,
      depth: depth,
      contactPoint: contactPoint,
    );
  }

  double _applyImpulse(
    PhysicsBody bA,
    PhysicsBody bB,
    PhysicsShape sA,
    PhysicsShape sB,
    ContactManifold manifold,
  ) {
    // Vectors from center of mass to contact point
    final rA = manifold.contactPoint - bA.position;
    final rB = manifold.contactPoint - bB.position;

    // Relative velocity at contact point
    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relativeVelocity = vB - vA;

    final velocityAlongNormal =
        relativeVelocity.dx * manifold.normal.dx +
        relativeVelocity.dy * manifold.normal.dy;
    if (velocityAlongNormal > 0) return 0.0;

    final raCrossN = rA.dx * manifold.normal.dy - rA.dy * manifold.normal.dx;
    final rbCrossN = rB.dx * manifold.normal.dy - rB.dy * manifold.normal.dx;

    final invMassSum =
        bA.invMass +
        bB.invMass +
        (raCrossN * raCrossN * bA.invInertia) +
        (rbCrossN * rbCrossN * bB.invInertia);

    if (invMassSum <= 0) return 0.0;

    // Combine restitution and friction
    final e = math.max(sA.bounciness, sB.bounciness);
    final mu = math.sqrt(sA.friction * sB.friction);

    double j = -(1.0 + e) * velocityAlongNormal;
    j /= invMassSum;

    final impulse = manifold.normal * j;
    bA.velocity -= impulse * bA.invMass;
    bA.angularVelocity -= raCrossN * j * bA.invInertia;
    bB.velocity += impulse * bB.invMass;
    bB.angularVelocity += rbCrossN * j * bB.invInertia;

    // Friction
    final tangent = relativeVelocity - manifold.normal * velocityAlongNormal;
    final tangentMag = tangent.distance;
    if (tangentMag > 0.0001) {
      final t = tangent / tangentMag;
      final raCrossT = rA.dx * t.dy - rA.dy * t.dx;
      final rbCrossT = rB.dx * t.dy - rB.dy * t.dx;
      final invMassSumT =
          bA.invMass +
          bB.invMass +
          (raCrossT * raCrossT * bA.invInertia) +
          (rbCrossT * rbCrossT * bB.invInertia);

      double jt = -relativeVelocity.dx * t.dx - relativeVelocity.dy * t.dy;
      jt /= invMassSumT;

      // Coulomb's law: clamp friction to normal impulse * friction coefficient
      final maxFriction = j * mu;
      jt = jt.clamp(-maxFriction, maxFriction);

      final frictionImpulse = t * jt;
      bA.velocity -= frictionImpulse * bA.invMass;
      bA.angularVelocity -= raCrossT * jt * bA.invInertia;
      bB.velocity += frictionImpulse * bB.invMass;
      bB.angularVelocity += rbCrossT * jt * bB.invInertia;
    }

    // Positional correction
    const percent = 0.2;
    const slop = 0.01;
    final correction =
        manifold.normal *
        (math.max(manifold.depth - slop, 0.0) /
            (bA.invMass + bB.invMass) *
            percent);
    bA.position -= correction * bA.invMass;
    bB.position += correction * bB.invMass;

    return j;
  }

  Offset _getTransformedPoint(Offset local, PhysicsBody body) {
    if (local == Offset.zero) return body.position;
    final cos = math.cos(body.rotation);
    final sin = math.sin(body.rotation);
    return body.position +
        Offset(
          local.dx * cos - local.dy * sin,
          local.dx * sin + local.dy * cos,
        );
  }
}

/// Geometric details of a collision intersection.
/// 
/// [ContactManifold] stores the normal, penetration depth, and exact 
/// point of contact between two [PhysicsShape]s.
/// 
/// ```dart
/// final manifold = ContactManifold(normal: Offset(0,1), depth: 0.5, contactPoint: Offset(10,10));
/// ```
class ContactManifold {
  /// The unit vector pointing from shape A to shape B.
  /// 
  /// Defines the direction of the separation force required to resolve 
  /// the collision.
  final Offset normal;

  /// The amount of overlap between the two shapes.
  /// 
  /// Used for positional correction to push the shapes apart.
  final double depth;

  /// The world-space position where the collision occurred.
  /// 
  /// Useful for positioning impact particles or sound sources.
  final Offset contactPoint;

  /// Creates a [ContactManifold] with specific intersection data.
  /// 
  /// * [normal]: The collision normal vector.
  /// * [depth]: The penetration distance.
  /// * [contactPoint]: The world-space hit point.
  ContactManifold({
    required this.normal,
    required this.depth,
    required this.contactPoint,
  });
}

/// Represents a persistent interaction between two colliding shapes.
/// 
/// [PhysicsContact] tracks the [ContactManifold] and the accumulated 
/// impulse applied during the last resolution step. Used by [PhysicsWorld].
/// 
/// ```dart
/// final contact = PhysicsContact(shapeAId: 1, shapeBId: 2, manifold: manifold);
/// ```
class PhysicsContact {
  /// The ID of the first shape in the contact pair.
  /// 
  /// Always corresponds to the body that the [manifold] normal points away from.
  final int shapeAId;

  /// The ID of the second shape in the contact pair.
  /// 
  /// Corresponds to the body being pushed along the [manifold] normal.
  final int shapeBId;

  /// The detailed geometry of the intersection.
  /// 
  /// Used by the solver to calculate resolution impulses.
  final ContactManifold manifold;

  /// The total impulse applied during the last resolution.
  /// 
  /// Can be used to determine the intensity of the collision for gameplay logic.
  final double impulse;

  /// Creates a [PhysicsContact] between two shapes.
  /// 
  /// * [shapeAId]: ID of the first shape.
  /// * [shapeBId]: ID of the second shape.
  /// * [manifold]: Geometric collision details.
  /// * [impulse]: Initial or accumulated impulse.
  PhysicsContact({
    required this.shapeAId,
    required this.shapeBId,
    required this.manifold,
    this.impulse = 0.0,
  });
}

/// The result of a single simulation step in the [PhysicsWorld].
/// 
/// [StepResult] contains the list of all [PhysicsContact]s that were 
/// processed during the integration. Returned by [PhysicsWorld.step].
/// 
/// ```dart
/// final result = world.step(1/60);
/// print(result.contacts.length);
/// ```
class StepResult {
  /// The list of active contacts resolved in this step.
  /// 
  /// Provides insight into which objects are currently touching.
  final List<PhysicsContact> contacts;

  /// Creates a [StepResult] with the provided [contacts].
  /// 
  /// * [contacts]: The list of collisions processed.
  StepResult({required this.contacts});
}
