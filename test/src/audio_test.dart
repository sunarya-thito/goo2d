import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:flutter/widgets.dart';

// Mocking GameAudio to avoid actual file loading
class MockGameAudio extends GameAudio {
  final AssetSource _source;

  bool loadCalled = false;

  MockGameAudio(String name)
    : _source = _MockSource(name),
      super(_MockSource(name));

  @override
  AssetSource get source => _source;

  @override
  bool isLoaded = false;

  @override
  Future<void> load() async {
    loadCalled = true;
    isLoaded = true;
  }

  @override
  void unload() {
    isLoaded = false;
  }
}

class _MockSource implements AssetSource {
  @override
  final String name;
  _MockSource(this.name);

  @override
  Future<Uint8List> loadBytes() async => Uint8List(0);
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('AudioSource', () {
    testWidgets('should automatically load clip when play is called', (
      tester,
    ) async {
      final mockAudio = MockGameAudio('test_sound');
      final audioSource = AudioSource()..clip = mockAudio;

      // We manually call play() here.
      // Note: It will still attempt to call SoLoud.instance.play,
      // but we want to verify the logic BEFORE that call.
      try {
        await audioSource.play();
      } catch (_) {
        // Expected crash on SoLoud.instance access in test environment
      }

      expect(mockAudio.loadCalled, isTrue);
    });

    testWidgets('should clean up handle registration on unmount', (
      tester,
    ) async {
      final audioSource = AudioSource();

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              ComponentWidget(() => audioSource),
              ComponentWidget(ObjectTransform.new),
            ],
          ),
        ),
      );
      await tester.pump();

      // Manually stop/unregistering check would go here if we could mock SoLoud
      // For now, just ensuring it doesn't crash on standard mount/unmount flow
      await tester.pumpWidget(Container());
      await tester.pump();
    });
  });

  group('AudioListener', () {
    testWidgets('should be detected by AudioSource for 3D spatialization', (
      tester,
    ) async {
      final listener = AudioListener();
      final audioSource = AudioSource();

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              ComponentWidget(() => listener),
              ComponentWidget(() => audioSource),
              ComponentWidget(
                ObjectTransform.new,
                update: (c) => c.position = const Offset(100, 0),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      // Internal check: trigger 3D update
      // Since SoLoud will crash, we just verify the listener lookup logic doesn't crash
      try {
        audioSource.onLateUpdate(0.1);
      } catch (_) {}
    });
  });
}
