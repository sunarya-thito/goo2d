import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart' as core;

/// The base class for all physical joint components.
/// 
/// Joints connect two [Rigidbody]s together and constrain their movement.
abstract class Joint extends Component with LifecycleListener {
  /// The other [Rigidbody] this joint connects to.
  /// 
  /// If null, the joint connects to a fixed point in the world.
  Rigidbody? connectedBody;

  /// The local anchor point on this object.
  Offset anchor = Offset.zero;

  /// The local anchor point on the [connectedBody].
  Offset connectedAnchor = Offset.zero;

  /// Whether the connected bodies should collide with each other.
  bool enableCollision = false;

  /// Unique ID used by the physics system.
  @internal
  int? internalId;

  /// Retrieves the Rigidbody component of the parent object.
  Rigidbody get rigidbody => gameObject.getComponent<Rigidbody>();

  @override
  void onMounted() {
    game.getSystem<PhysicsSystem>()?.registerJoint(this);
  }

  @override
  void onUnmounted() {
    game.getSystem<PhysicsSystem>()?.unregisterJoint(this);
  }

  /// Internal method to create the core joint representation for simulation.
  @internal
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId);
}

/// A joint that maintains a fixed distance between two rigidbodies.
class DistanceJoint extends Joint {
  /// The distance to maintain. If 0, the distance at creation is used.
  double distance = 0.0;

  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    double finalDist = distance;
    if (finalDist <= 0) {
      // Calculate initial distance
      final pA = rigidbody.transform.localToWorld(anchor);
      final pB = connectedBody?.transform.localToWorld(connectedAnchor) ??
          connectedBody?.transform.position ?? 
          Offset.zero; // Fallback for world anchor
      finalDist = (pB - pA).distance;
    }

    return core.DistanceJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      anchorA: anchor,
      anchorB: connectedAnchor,
      length: finalDist,
    );
  }
}

/// A joint that allows a body to rotate around a pivot point.
class HingeJoint extends Joint {
  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    return core.HingeJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      anchorA: anchor,
      anchorB: connectedAnchor,
    );
  }
}

/// A joint that acts like a spring between two points.
class SpringJoint extends Joint {
  /// The ideal distance the spring tries to maintain.
  double restLength = 0.0;

  /// How stiff the spring is. Higher values result in more forceful correction.
  double stiffness = 100.0;

  /// How much energy is lost over time. Prevents infinite oscillation.
  double damping = 10.0;

  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    return core.SpringJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      anchorA: anchor,
      anchorB: connectedAnchor,
      restLength: restLength,
      stiffness: stiffness,
      damping: damping,
    );
  }
}

/// A joint that allows linear movement along a specific axis.
class SliderJoint extends Joint {
  /// The axis of movement in local space.
  Offset axis = const Offset(1, 0);

  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    return core.SliderJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      anchorA: anchor,
      anchorB: connectedAnchor,
      axis: axis,
    );
  }
}

/// A joint designed for vehicle wheels, with suspension and rotation.
class WheelJoint extends Joint {
  /// The direction of suspension movement in local space.
  Offset suspensionAxis = const Offset(0, 1);

  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    return core.WheelJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      anchorA: anchor,
      anchorB: connectedAnchor,
      suspensionAxis: suspensionAxis,
    );
  }
}

/// A joint that locks two bodies together at their current relative transform.
class FixedJoint extends Joint {
  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    final rbA = rigidbody;
    final rbB = connectedBody;
    double refAngle = 0.0;
    if (rbB != null) {
      refAngle = rbB.transform.angle - rbA.transform.angle;
    }

    return core.FixedJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      localAnchorA: anchor,
      localAnchorB: connectedAnchor,
      referenceAngle: refAngle,
    );
  }
}

/// A joint that applies friction to resist relative motion.
class FrictionJoint extends Joint {
  /// Maximum linear friction force.
  double maxForce = 10.0;
  /// Maximum rotational friction torque.
  double maxTorque = 1.0;

  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    return core.FrictionJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      localAnchorA: anchor,
      localAnchorB: connectedAnchor,
      maxForce: maxForce,
      maxTorque: maxTorque,
    );
  }
}

/// A joint that maintains a constant relative offset and angle.
class RelativeJoint extends Joint {
  /// Target linear offset.
  Offset linearOffset = Offset.zero;
  /// Target angular offset.
  double angularOffset = 0.0;
  /// Maximum correction force.
  double maxForce = 1000.0;
  /// Maximum correction torque.
  double maxTorque = 1000.0;

  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    return core.RelativeJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      linearOffset: linearOffset,
      angularOffset: angularOffset,
      maxForce: maxForce,
      maxTorque: maxTorque,
    );
  }
}

/// A joint that pulls a body towards a world position.
class TargetJoint extends Joint {
  /// The world position to pull towards.
  Offset target = Offset.zero;
  /// Maximum pull force.
  double maxForce = 5000.0;
  /// Speed of response.
  double frequency = 5.0;
  /// Oscillation damping.
  double dampingRatio = 0.7;

  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    return core.TargetJoint(
      id: id,
      bodyAId: bodyAId,
      bodyBId: -1, // No connected body for target joint
      target: target,
      maxForce: maxForce,
      frequency: frequency,
      dampingRatio: dampingRatio,
    );
  }
}
