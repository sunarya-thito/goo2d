import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/ticker.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Game', () {
    testWidgets('should provide GameEngine via GameProvider', (tester) async {
      GameEngine? foundEngine;

      await tester.pumpWidget(
        Game(
          child: Builder(
            builder: (context) {
              foundEngine = GameProvider.of(context);
              return Container();
            },
          ),
        ),
      );

      expect(foundEngine, isNotNull);
    });

    testWidgets(
      'should automatically inject World, GameLoop, and GameRenderer',
      (
        tester,
      ) async {
        await tester.pumpWidget(Game(child: Container()));

        expect(find.byType(World), findsOneWidget);
        expect(find.byType(GameLoop), findsOneWidget);
        expect(find.byType(GameRenderer), findsOneWidget);
      },
    );

    testWidgets('should support custom GameEngine instance', (tester) async {
      final customEngine = GameEngine();
      GameEngine? foundEngine;

      await tester.pumpWidget(
        Game(
          game: customEngine, // Corrected from engine
          child: Builder(
            builder: (context) {
              foundEngine = GameProvider.of(context);
              return Container();
            },
          ),
        ),
      );

      expect(foundEngine, equals(customEngine));
    });

    testWidgets('should allow nesting multiple game instances', (tester) async {
      GameEngine? engine1;
      GameEngine? engine2;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Game(
                child: Builder(
                  builder: (c) {
                    engine1 = GameProvider.of(c);
                    return Container();
                  },
                ),
              ),
              Game(
                child: Builder(
                  builder: (c) {
                    engine2 = GameProvider.of(c);
                    return Container();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(engine1, isNotNull);
      expect(engine2, isNotNull);
      expect(engine1, isNot(equals(engine2)));
    });
  });
}
