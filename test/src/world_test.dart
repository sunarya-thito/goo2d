import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:flutter/widgets.dart';
import 'package:goo2d/src/world.dart';

class _MockPointerReceiver extends Component with PointerReceiver {
  final void Function() onDown;
  _MockPointerReceiver(this.onDown);

  @override
  void onPointerDown(PointerDownEvent event) => onDown();
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('RenderWorld', () {
    testWidgets(
      'should render children with camera transform when camera is ready',
      (tester) async {
        final game = GameEngine();

        await tester.pumpWidget(
          Game(
            game: game, // Corrected from engine
            child: GameWidget(
              key: const GameTag('MainCamera'),
              components: () => [
                Camera(),
                ObjectTransform()..position = const Offset(100, 200),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(game.cameras.isReady, isTrue);

        final camera = game.cameras.main;
        expect(
          camera.gameObject.getComponent<ObjectTransform>().position,
          const Offset(100, 200),
        );
      },
    );

    testWidgets(
      'should fall back to default rendering when camera is NOT ready',
      (tester) async {
        await tester.pumpWidget(Game(child: SizedBox(width: 100, height: 100)));
        await tester.pump();

        final renderWorld = tester.allRenderObjects
            .whereType<RenderWorld>()
            .firstOrNull;
        expect(renderWorld, isNotNull);
        expect(renderWorld!.game.cameras.isReady, isFalse);
      },
    );

    testWidgets(
      'should correctly transform hit test positions from screen to world space',
      (tester) async {
        bool hit = false;
        await tester.pumpWidget(
          Game(
            child: GameWidget(
              key: const GameTag('MainCamera'),
              components: () => [
                Camera()..orthographicSize = 5.0,
                ObjectTransform()..position = Offset.zero,
                _MockPointerReceiver(() => hit = true),
                BoxCollider()..size = const Size(100, 100),
              ],
            ),
          ),
        );
        await tester.pump();

        await tester.tapAt(const Offset(400, 300));
        expect(hit, isTrue);
      },
    );
  });
}
