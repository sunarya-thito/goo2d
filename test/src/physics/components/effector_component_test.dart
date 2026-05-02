import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/bridge/physics_bridge.dart';

class MockPhysicsBridge implements PhysicsBridge {
  final Map<int, List<Offset>> appliedForces = {};

  @override
  void applyForce(int bodyId, Offset force) {
    appliedForces.putIfAbsent(bodyId, () => []).add(force);
  }

  @override
  Future<void> init(worldId, onStepResult, onRaycastResult) async {}
  @override
  void createWorld() {}
  @override
  void destroyWorld() {}
  @override
  void addBody(id, type, {mass = 1.0, drag = 0.0, angularDrag = 0.05, freezeRotation = false, gravityScale = 1.0, position = Offset.zero, rotation = 0.0}) {}
  @override
  void removeBody(id) {}
  @override
  void updateBody(id, {mass = 1.0, drag = 0.0, angularDrag = 0.05, freezeRotation = false, gravityScale = 1.0}) {}
  @override
  void addShape(id, bodyId, collider) {}
  @override
  void removeShape(id) {}
  @override
  void addJoint(id, joint) {}
  @override
  void removeJoint(id) {}
  @override
  void applyImpulse(bodyId, impulse) {}
  @override
  void applyTorque(bodyId, torque) {}
  @override
  void applyAngularImpulse(bodyId, impulse) {}
  @override
  void setGravity(gravity) {}
  @override
  void syncVelocity(bodyId, velocity) {}
  @override
  void syncAngularVelocity(bodyId, velocity) {}
  @override
  void step(dt, sync) {}
  @override
  void raycast(requestId, origin, direction, maxDistance) {}
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Effector Components', () {
    testWidgets('AreaEffector applies force', (tester) async {
      final mockBridge = MockPhysicsBridge();
      final physics = PhysicsSystem()..bridgeOverride = mockBridge;
      final engine = GameEngine({
        TickerState.new,
        InputSystem.new,
        () => physics,
        CameraSystem.new,
        ScreenSystem.new,
        AudioSystem.new,
      });

      final rb = Rigidbody();
      final collider = BoxCollider();
      final effector = AreaEffector()
        ..forceMagnitude = 1000.0
        ..forceAngle = 0.0
        ..useGlobalAngle = true;
      
      await tester.pumpWidget(
        Game(
          game: engine,
          child: GameObjectWidget(
            children: [
              GameObjectWidget(
                name: 'EffectorObj',
                children: [
                  ComponentWidget(() => ObjectTransform()),
                  ComponentWidget(() => BoxCollider()..isTrigger = true),
                  ComponentWidget(() => effector),
                ],
              ),
              GameObjectWidget(
                name: 'TargetObj',
                children: [
                  ComponentWidget(() => ObjectTransform()..position = const Offset(100, 100)),
                  ComponentWidget(() => rb),
                  ComponentWidget(() => collider),
                ],
              ),
            ],
          ),
        ),
      );

      // Manually trigger the effector logic
      effector.onTriggerStay(collider);
      
      // Verify force was applied to the body.
      expect(mockBridge.appliedForces, isNotEmpty);
      final forces = mockBridge.appliedForces.values.first;
      expect(forces.first, const Offset(1000, 0));
    });

    testWidgets('PlatformEffector updates collider', (tester) async {
      final collider = BoxCollider();
      final effector = PlatformEffector()
        ..useOneWay = true
        ..oneWayArc = 1.0
        ..rotationalOffset = 0.5;
      
      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              GameObjectWidget(
                children: [
                  ComponentWidget(() => ObjectTransform()..angle = 0.2),
                  ComponentWidget(() => collider),
                  ComponentWidget(() => effector),
                ],
              ),
            ],
          ),
        ),
      );

      expect(collider.isOneWay, isTrue);
      expect(collider.oneWayArc, 1.0);
      expect(collider.oneWayAngle, closeTo(0.7, 0.001)); // 0.2 + 0.5
    });
  });
}
