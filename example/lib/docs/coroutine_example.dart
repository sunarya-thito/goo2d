import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

class CoroutineExample extends StatefulWidget {
  const CoroutineExample({super.key});

  @override
  State<CoroutineExample> createState() => _CoroutineExampleState();
}

class _CoroutineExampleState extends State<CoroutineExample> {
  @override
  Widget build(BuildContext context) {
    return const Game(child: CoroutineWorld());
  }
}

class CoroutineWorld extends StatefulGameWidget {
  const CoroutineWorld({super.key});

  @override
  GameState<CoroutineWorld> createState() => _CoroutineWorldState();
}

class _CoroutineWorldState extends GameState<CoroutineWorld> {
  String _message = 'Tap to Start Boss Sequence';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
  }

  // Coroutines must return Stream and can use async*
  Stream bossSequence() async* {
    setState(() {
      _message = 'Boss Appearing...';
      _isRunning = true;
    });

    final transform = getComponent<ObjectTransform>();
    
    // 1. Lerping Position (Manually over 1 second)
    final startPos = const Offset(0, -5);
    final endPos = Offset.zero;
    double elapsed = 0;
    while (elapsed < 1.0) {
      elapsed += game.ticker.deltaTime;
      final t = elapsed / 1.0;
      transform.position = Offset.lerp(startPos, endPos, Curves.easeInOut.transform(t))!;
      yield null; // Wait for next frame
    }

    // 2. Nested Sub-coroutine (Waiting for it to finish)
    setState(() => _message = 'Charging Energy...');
    yield chargeEffect();

    // 3. Fire and Forget Sub-coroutine (Stopping it later)
    setState(() => _message = 'Firing Lasers! (Press SPACE to Stop)');
    final laserRoutine = startCoroutine(fireLasers);
    
    // Wait for user to press Space or 3 seconds pass
    double timer = 0;
    while (timer < 3.0 && !game.input.keyboard.space.isPressed) {
      timer += game.ticker.deltaTime;
      yield null;
    }

    // 4. Stop the specific sub-routine
    stopCoroutine(laserRoutine);
    setState(() => _message = 'Sequence Complete!');
    yield WaitForSeconds(2.0);
    
    setState(() {
      _message = 'Tap to Restart';
      _isRunning = false;
    });
  }

  Stream chargeEffect() async* {
    final transform = getComponent<ObjectTransform>();
    for (int i = 0; i < 10; i++) {
      transform.scale = Offset(1.0 + i * 0.05, 1.0 + i * 0.05);
      yield WaitForSeconds(0.05);
    }
    for (int i = 10; i >= 0; i--) {
      transform.scale = Offset(1.0 + i * 0.05, 1.0 + i * 0.05);
      yield WaitForSeconds(0.05);
    }
  }

  Stream fireLasers() async* {
    while (true) {
      // Logic for firing lasers...
      print('Laser Fired!');
      yield WaitForSeconds(0.2);
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()..position = const Offset(0, -5),
      ],
      children: [
        CanvasWidget(
          child: GestureDetector(
            onTap: () {
              if (!_isRunning) startCoroutine(bossSequence);
            },
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.adb, size: 80, color: Colors.redAccent),
                  const SizedBox(height: 20),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
