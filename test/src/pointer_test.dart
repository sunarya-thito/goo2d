import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/component.dart';

class MockPointerReceiver extends Component with PointerReceiver {
  int downCount = 0;
  int upCount = 0;
  Offset? lastPosition;

  @override
  void onPointerDown(PointerDownEvent event) {
    downCount++;
    lastPosition = event.localPosition;
  }

  @override
  void onPointerUp(PointerUpEvent event) {
    upCount++;
  }
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Pointer', () {
    testWidgets('should dispatch events to PointerReceiver when hit', (tester) async {
      final receiver = internalCreateComponent(MockPointerReceiver.new) as MockPointerReceiver;
      final collider = internalCreateComponent(BoxCollider.new.withParams((c) {
        c.size = const Size(100, 100);
        c.offset = const Offset(50, 50);
      })) as BoxCollider;
      
      await tester.pumpWidget(
        Game(
          child: Center(
            child: GameWidget(
              components: [
                ScreenTransform.new.withParams(
                  (c) => c.constraints = const BoxConstraints.tightFor(width: 100, height: 100),
                ),
                () => receiver,
                () => collider,
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final widgetCenter = tester.getCenter(find.byType(GameWidget));
      
      await tester.tapAt(widgetCenter);
      await tester.pump();

      expect(receiver.downCount, equals(1));
      expect(receiver.upCount, equals(1));
    });

    testWidgets('should NOT dispatch events when NOT hit', (tester) async {
      final receiver = internalCreateComponent(MockPointerReceiver.new) as MockPointerReceiver;
      final collider = internalCreateComponent(BoxCollider.new.withParams((c) {
        c.size = const Size(50, 50);
        c.offset = const Offset(25, 25);
      })) as BoxCollider;

      await tester.pumpWidget(
        Game(
          child: Center(
            child: GameWidget(
              components: [
                ScreenTransform.new.withParams(
                  (c) => c.constraints = const BoxConstraints.tightFor(width: 100, height: 100),
                ),
                () => receiver,
                () => collider,
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap at (75, 75) local - inside the 100x100 widget but outside the 50x50 collider
      final widgetTopLeft = tester.getTopLeft(find.byType(GameWidget));
      await tester.tapAt(widgetTopLeft + const Offset(75, 75));
      await tester.pump();

      expect(receiver.downCount, equals(0));
    });

    testWidgets('should handle move and hover events', (tester) async {
      final receiver = internalCreateComponent(MockPointerReceiver.new) as MockPointerReceiver;
      final collider = internalCreateComponent(BoxCollider.new.withParams((c) {
        c.size = const Size(100, 100);
        c.offset = const Offset(50, 50);
      })) as BoxCollider;
      
      await tester.pumpWidget(
        Game(
          child: Center(
            child: GameWidget(
              components: [
                ScreenTransform.new.withParams(
                  (c) => c.constraints = const BoxConstraints.tightFor(width: 100, height: 100),
                ),
                () => receiver,
                () => collider,
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(GameWidget));
      
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await tester.pump();
      
      // Hover/Move usually require mouse pointer kind
      await gesture.moveTo(center + const Offset(10, 10));
      await tester.pump();
    });
  });
}
