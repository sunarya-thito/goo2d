import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Coroutine', () {
    testWidgets('should run a simple coroutine', (tester) async {
      bool reached = false;
      Stream myCoroutine() async* {
        yield null; // Wait 1 frame
        reached = true;
      }

      await tester.pumpWidget(
        Game(
          child: GameWidget(),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.startCoroutine(myCoroutine);
      await tester.idle(); // Let the Future in setupCoroutine run
      expect(reached, isFalse);

      await tester.pump(); // Frame 1
      await tester.pump(); // Frame 2
      expect(reached, isTrue);
    });

    testWidgets('should wait for seconds', (tester) async {
      int count = 0;
      Stream myCoroutine() async* {
        count++;
        yield WaitForSeconds(0.1);
        count++;
      }

      await tester.pumpWidget(
        Game(
          child: GameWidget(),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.startCoroutine(myCoroutine);
      await tester.idle();
      await tester.pump(); 
      expect(count, equals(1));

      // Wait 100ms
      await tester.pump(const Duration(milliseconds: 110));
      expect(count, equals(2));
    });

    testWidgets('should wait until condition is met', (tester) async {
      bool condition = false;
      bool reached = false;
      Stream myCoroutine() async* {
        yield WaitUntil(() => condition);
        reached = true;
      }

      await tester.pumpWidget(
        Game(
          child: GameWidget(),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.startCoroutine(myCoroutine);
      await tester.idle();
      await tester.pump(); 
      expect(reached, isFalse);

      await tester.pump(const Duration(milliseconds: 16));
      expect(reached, isFalse);

      condition = true;
      await tester.pump(); // Next frame triggers the check
      expect(reached, isTrue);
    });

    testWidgets('should stop specific coroutine', (tester) async {
      bool reached = false;
      Stream myCoroutine() async* {
        yield WaitForSeconds(1.0);
        reached = true;
      }

      await tester.pumpWidget(
        Game(
          child: GameWidget(),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      final future = gameObject.startCoroutine(myCoroutine);
      await tester.idle(); // Ensure it added itself to the list
      
      gameObject.stopCoroutine(future);

      await tester.pump(const Duration(seconds: 2));
      expect(reached, isFalse);
    });

    testWidgets('should stop all coroutines on unmount', (tester) async {
      int count = 0;
      Stream myCoroutine() async* {
        while (true) {
          yield null;
          count++;
        }
      }

      await tester.pumpWidget(
        Game(
          child: GameWidget(),
        ),
      );
      await tester.pump();
      final obj = tester.element(find.byType(GameWidget)) as GameObject;
      obj.startCoroutine(myCoroutine);
      await tester.idle();

      await tester.pump();
      expect(count, greaterThan(0));
      final lastCount = count;

      // Unmount
      await tester.pumpWidget(Game(child: const SizedBox()));
      await tester.pump();
      await tester.idle();
      
      // Pump a few more times to ensure it's really stopped
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      
      // It might increment once more if it was already waiting for a frame
      expect(count, lessThanOrEqualTo(lastCount + 1));
      final finalCount = count;
      
      await tester.pump(const Duration(milliseconds: 100));
      expect(count, equals(finalCount));
    });

    testWidgets('should handle nested coroutines', (tester) async {
      bool innerReached = false;
      Stream inner() async* {
        yield null;
        innerReached = true;
      }

      Stream outer() async* {
        yield inner();
      }

      await tester.pumpWidget(
        Game(
          child: GameWidget(),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.startCoroutine(outer);
      await tester.idle();
      await tester.pump(); // Start outer, start inner, inner yields null
      await tester.pump(); // Inner continues after frame
      await tester.idle(); // Finish microtasks
      
      expect(innerReached, isTrue);
    });
  });
}
