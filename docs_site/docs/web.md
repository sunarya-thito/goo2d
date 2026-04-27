# Web Platform

Developing games for the web with Flutter requires specific considerations for performance and feature support. Goo2D is designed to be highly efficient on the web, especially when using modern Flutter features.

## Performance: WASM and CanvasKit

For the best possible performance, it is **highly recommended** to use the WASM compiler and the CanvasKit renderer. WASM significantly improves execution speed for game logic, while CanvasKit provides much faster and more consistent 2D rendering compared to the default HTML renderer.

### Building for Web with WASM
To build your game with WASM support:

```bash
flutter build web --wasm
```

:::tip
Using `--wasm` significantly optimizes many low-level engine operations, leading to much higher and more stable frame rates.
:::

### Running Locally with WASM
To test your game locally with WASM enabled:

```bash
flutter run -d chrome --wasm
```

---

## Audio Setup (Web)

The underlying `flutter_soloud` engine used by Goo2D requires specific JavaScript files to be manually initialized on the Web. If you skip this, audio will not work and you will see obfuscated console errors.

### 1. Update `index.html`
Open `web/index.html` and add the following scripts inside the `<body>` tag, **before** the `flutter.js` script:

```html
<!-- Add these lines for Goo2D Audio support -->
<script src="assets/packages/flutter_soloud/web/libflutter_soloud_plugin.js" defer></script>
<script src="assets/packages/flutter_soloud/web/init_module.dart.js" defer></script>
```

### 2. Deployment
When deploying your game, ensure these assets are correctly included in your build output. If you are using standard Flutter build commands, they should be copied automatically to the `build/web/assets` directory.

For more details on audio usage, see the [Audio Cookbook](./cookbook/audio).
