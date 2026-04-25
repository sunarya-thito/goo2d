# Installation

> **⚠️ Note:** Goo2D is currently under heavy development and is not yet published to pub.dev.

To use Goo2D, you'll need to add it to your Flutter project as a local or git dependency.

### Adding the Dependency

In your `pubspec.yaml`, add the `goo2d` package:

```yaml
dependencies:
  flutter:
    sdk: flutter
  goo2d:
    path: ../path/to/goo2d # Or use a git url if applicable
```

Run `flutter pub get` to install the package.

### Setting up the GameScene

To run a Goo2D game, you need to wrap your game hierarchy in a `GameScene`. The `GameScene` sets up the `GameTicker` (which drives the frame loop), initializes the `InputSystem`, and handles the global collision passes.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GameScene(
          child: MyRootGameObject(),
        ),
      ),
    ),
  );
}
```

The `child` of the `GameScene` must be a widget that evaluates to a `GameObject` (such as a `StatefulGameWidget` or `GameWidget`).
