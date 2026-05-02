import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

abstract class Effector extends Component with TriggerListener {
  bool enabled = true;
  double forceMagnitude = 1000.0;
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();

  @override
  void onTriggerStay(Collider other) {
    if (!enabled) return;

    final rb = other.gameObject.tryGetComponent<Rigidbody>();
    if (rb != null && rb.type == RigidbodyType.dynamic) {
      applyEffectorForce(rb, other);
    }
  }

  void applyEffectorForce(Rigidbody rb, Collider other);
}

class AreaEffector extends Effector {
  double forceAngle = 0.0;
  bool useGlobalAngle = false;

  @override
  void applyEffectorForce(Rigidbody rb, Collider other) {
    double angle = forceAngle;
    if (!useGlobalAngle) {
      angle += transform.angle;
    }

    final force = Offset(math.cos(angle), math.sin(angle)) * forceMagnitude;
    rb.addForce(force);
  }
}

class PointEffector extends Effector {
  @override
  void applyEffectorForce(Rigidbody rb, Collider other) {
    final diff =
        transform.position -
        rb.gameObject.getComponent<ObjectTransform>().position;
    if (diff.distanceSquared > 0) {
      final direction = diff / diff.distance;
      rb.addForce(direction * forceMagnitude);
    }
  }
}

class SurfaceEffector extends Component with CollisionListener {
  bool enabled = true;
  double speed = 200.0;
  double forceMagnitude = 5000.0;
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();

  @override
  void onCollisionStay(Collision collision) {
    if (!enabled) return;

    final rb = collision.rigidbody;
    if (rb != null && rb.type == RigidbodyType.dynamic) {
      // Calculate tangent (perpendicular to contact normal)
      final normal = collision.normal;
      final tangent = Offset(-normal.dy, normal.dx);

      // Apply directional force along the surface
      rb.addForce(tangent * speed * forceMagnitude * 0.01);
    }
  }
}

class BuoyancyEffector extends Effector {
  double density = 1.0;
  double surfaceLevel = 0.0;
  double linearDrag = 2.0;
  double angularDrag = 1.0;

  @override
  void applyEffectorForce(Rigidbody rb, Collider other) {
    final pos = rb.gameObject.getComponent<ObjectTransform>().position;
    if (pos.dy > surfaceLevel) {
      final depth = pos.dy - surfaceLevel;
      final buoyancy = Offset(0, -depth * density * 1000);
      rb.addForce(buoyancy);

      // Apply damping to simulate fluid resistance
      rb.velocity *= (1.0 - linearDrag * 0.01);
      rb.angularVelocity *= (1.0 - angularDrag * 0.01);
    }
  }
}

class PlatformEffector extends Component with LifecycleListener, Tickable {
  bool useOneWay = true;
  double oneWayArc = math.pi;
  double rotationalOffset = 0.0;
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();

  @override
  void onMounted() {
    _updateCollider();
  }

  void _updateCollider() {
    final collider = gameObject.tryGetComponent<Collider>();
    if (collider != null) {
      collider.isOneWay = useOneWay;
      collider.oneWayArc = oneWayArc;
      // Pass-through direction is opposite to the solid surface normal
      final angle = transform.angle + rotationalOffset;
      collider.oneWayAngle = angle;

      if (collider is CompositeCollider) {
        for (final shape in collider.shapes) {
          shape.isOneWay = useOneWay;
          shape.oneWayArc = oneWayArc;
          shape.oneWayAngle = angle;
        }
      }
    }
  }

  @override
  void onUpdate(double dt) {
    _updateCollider();
  }
}
