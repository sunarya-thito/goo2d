import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

class MockSystem implements GameSystem {
  @override
  late final GameEngine game;
  @override
  bool get gameAttached => _attached;
  bool _attached = false;
  bool disposed = false;

  @override
  void attach(GameEngine game) {
    this.game = game;
    _attached = true;
  }

  @override
  void dispose() => disposed = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('GameSystem', () {
    test('GameEngine should initialize default systems', () {
      final engine = GameEngine();
      engine.initialize();

      expect(engine.hasSystem<TickerState>(), isTrue);
      expect(engine.hasSystem<InputSystem>(), isTrue);
      expect(engine.hasSystem<PhysicsSystem>(), isTrue);
      expect(engine.hasSystem<CameraSystem>(), isTrue);
      expect(engine.hasSystem<ScreenSystem>(), isTrue);
      expect(engine.hasSystem<AudioSystem>(), isTrue);
    });

    test('GameEngine should support custom system configurations', () {
      final engine = GameEngine({
        MockSystem.new,
      });
      engine.initialize();

      expect(engine.hasSystem<MockSystem>(), isTrue);
      expect(engine.hasSystem<TickerState>(), isFalse);
    });

    test('Operator - and ~ should exclude systems', () {
      final engine = GameEngine({
        ...GameEngine.defaultSystems,
        -InputSystem.new,
        ~PhysicsSystem.new,
      });
      engine.initialize();

      expect(engine.hasSystem<TickerState>(), isTrue);
      expect(engine.hasSystem<InputSystem>(), isFalse);
      expect(engine.hasSystem<PhysicsSystem>(), isFalse);
      expect(engine.hasSystem<CameraSystem>(), isTrue);
    });

    test('Systems should be disposed when engine is disposed', () {
      final system = MockSystem();
      final engine = GameEngine({
        () => system,
      });
      engine.initialize();
      expect(system.gameAttached, isTrue);

      engine.dispose();
      expect(system.disposed, isTrue);
    });

    test('getSystem should return null for missing systems', () {
      final engine = GameEngine({});
      expect(engine.getSystem<TickerState>(), isNull);
    });
  });
}
