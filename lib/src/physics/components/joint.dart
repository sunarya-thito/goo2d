import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart' as core;

abstract class Joint extends Component with LifecycleListener {
  Rigidbody? connectedBody;
  Offset anchor = Offset.zero;
  Offset connectedAnchor = Offset.zero;
  bool enableCollision = false;
  @internal
  int? internalId;
  Rigidbody get rigidbody => gameObject.getComponent<Rigidbody>();

  @override
  void onMounted() {
    game.getSystem<PhysicsSystem>()?.registerJoint(this);
  }

  @override
  void onUnmounted() {
    game.getSystem<PhysicsSystem>()?.unregisterJoint(this);
  }

  @internal
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId);
}

class DistanceJoint extends Joint {
  double distance = 0.0;

  @override
  core.Joint createCoreJoint(int id, int bodyAId, int bodyBId) {
    double finalDist = distance;
    if (finalDist <= 0) {
      // Calculate initial distance
      final pA = rigidbody.transform.localToWorld(anchor);
      final pB =
          connectedBody?.transform.localToWorld(connectedAnchor) ??
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

class SpringJoint extends Joint {
  double restLength = 0.0;
  double stiffness = 100.0;
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

class SliderJoint extends Joint {
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

class WheelJoint extends Joint {
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

class FrictionJoint extends Joint {
  double maxForce = 10.0;
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

class RelativeJoint extends Joint {
  Offset linearOffset = Offset.zero;
  double angularOffset = 0.0;
  double maxForce = 1000.0;
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

class TargetJoint extends Joint {
  Offset target = Offset.zero;
  double maxForce = 5000.0;
  double frequency = 5.0;
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
