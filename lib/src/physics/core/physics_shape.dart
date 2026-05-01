import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';

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
  /// Whether the shape allows one-way collisions.
  /// 
  /// If true, collisions will only be resolved if the relative velocity 
  /// and contact normal align with the specified [oneWayAngle].
  bool isOneWay = false;
  /// The world-space angle (in radians) of the one-way pass-through direction.
  /// 
  /// For a standard platform you land on, this would point upwards (-PI/2).
  double oneWayAngle = 0.0;
  /// The angular width of the arc where collisions are active.
  /// 
  /// A value of PI (180 degrees) means any contact within the front 
  /// hemisphere is resolved.
  double oneWayArc = 3.141592653589793; // math.pi

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
/// a radius comparison.
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

/// The orientation of a capsule shape.
enum CapsuleDirection {
  /// Stretches along the Y axis.
  vertical,

  /// Stretches along the X axis.
  horizontal
}

/// A capsule shape consisting of a cylinder with two hemispherical ends.
/// 
/// Capsules are excellent for humanoids as they prevent "snagging" 
/// on corner edges.
/// 
/// ```dart
/// final capsule = PhysicsCapsule(10.0, 40.0, CapsuleDirection.vertical);
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

  /// The orientation of the capsule's primary axis.
  /// 
  /// Determines whether the capsule stretches along the X or Y axis.
  final CapsuleDirection direction;

  /// Creates a [PhysicsCapsule] with given dimensions and orientation.
  /// 
  /// * [radius]: The thickness radius.
  /// * [height]: The total length.
  /// * [direction]: Orientation of the capsule.
  PhysicsCapsule(this.radius, this.height, this.direction);
}

/// A convex polygonal shape defined by a set of vertices.
/// 
/// Polygons provide the most flexibility for custom shapes.
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
