import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'package:example/main.dart' as app;
import 'package:example/docs/input_example.dart';
import 'package:example/docs/collision_example.dart';
import 'package:example/docs/camera_example.dart';
import 'package:example/docs/coroutine_example.dart';
import 'package:example/docs/sprites_example.dart';
import 'package:example/docs/audio_example.dart';
import 'package:google_fonts/google_fonts.dart';

/// This is the entry point used exclusively for the GitHub Pages documentation site.
/// It acts as a router to load specific "Cookbook" examples based on the URL hash,
/// keeping the main pub.dev example file pure.
void main() {
  runApp(const DocsRouterApp());
}

class DocsRouterApp extends StatefulWidget {
  const DocsRouterApp({super.key});

  @override
  State<DocsRouterApp> createState() => _DocsRouterAppState();
}

class _DocsRouterAppState extends State<DocsRouterApp> {
  String _route = '/collision';

  @override
  void initState() {
    super.initState();
    // Parse the URL hash on Web
    // Example: https://goo2d.dev/examples/#/input
    final path = Uri.base.fragment;
    if (path.isNotEmpty) {
      _route = path;
    }
  }

  Widget _getExampleForRoute() {
    switch (_route) {
      case '/':
      case '/battle':
        // The main showcase game loads its specific assets
        return PlayableExample(
          builder: (context) => FutureBuilder(
            future: app.loadAllGameAssets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              return DefaultTextStyle(
                style: GoogleFonts.jersey10(letterSpacing: 2),
                child: const Game(
                  child: app.BattleWorld(),
                ),
              );
            },
          ),
        );
      case '/input':
        return PlayableExample(
          builder: (context) => const Game(child: InputExample()),
        );
      case '/collision':
        return PlayableExample(
          builder: (context) => const Game(child: CollisionExample()),
        );
      case '/camera':
        return PlayableExample(
          builder: (context) => const Game(child: CameraExample()),
        );
      case '/coroutine':
        return PlayableExample(
          builder: (context) => const Game(child: CoroutineExample()),
        );
      case '/sprites':
        return PlayableExample(
          builder: (context) => const Game(child: SpriteExample()),
        );
      case '/audio':
        return PlayableExample(
          builder: (context) => const Game(child: AudioExample()),
        );
      default:
        return const Center(
          child: Text(
            'Example not found',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.black),
      home: Scaffold(
        body: _getExampleForRoute(),
      ),
    );
  }
}

class PlayableExample extends StatefulWidget {
  final WidgetBuilder builder;

  const PlayableExample({super.key, required this.builder});

  @override
  State<PlayableExample> createState() => _PlayableExampleState();
}

class _PlayableExampleState extends State<PlayableExample> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    if (_isPlaying) {
      return widget.builder(context);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isPlaying = true),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.play_circle_fill, size: 80, color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'Click to Play',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
