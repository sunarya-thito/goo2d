---
applyTo: "**"
---

<dotguides>
This workspace uses the *Dotguides* system for providing context-aware coding guidance for open source packages it uses. Use the `read_docs` tool to load documentation files relevant to specific tasks.

## Detected Languages

Language: flutter
Runtime: flutter
Version: ^3.11.4
Package Manager: pub

## Package Usage Guides

The following are the discovered package usage guides for this workspace. FOLLOW THEIR GUIDANCE CAREFULLY. Not all packages have discoverable guidance files.

<package name="goo2d">
<usage_guide>
# Goo2D Usage Guide (vunknown)

Goo2D is a low-level, high-performance 2D game engine for Flutter. It uses a composition-based architecture similar to an ECS (Entity Component System).

## Core Architecture
- **Game**: The root widget that hosts the engine.
- **StatefulGameWidget**: The base for complex game entities and the world container.
- **GameState**: Manages the lifecycle and child widgets of a `StatefulGameWidget`.
- **GameObject**: Implicitly created by `StatefulGameWidget`. Access via `game` or `gameObject` in components/behaviors.
- **Components**: Data-holding classes like `ObjectTransform` (position/rotation) and `SpriteRenderer`.
- **Behaviors**: Logic-holding classes. Mix in `Tickable` (updates) or `LateTickable` (updates after others).

## Implementation Rules
- **Delta Time**: Always multiply movement and timers by `dt` in `onUpdate(double dt)` for frame-rate independence.
- **Transform**: Every visual object requires an `ObjectTransform` component. Access it via `getComponent<ObjectTransform>()`.
- **Positioning**: Use `Offset` for 2D positions.
- **Input**: Use `createInputAction` in `initState` to define logical controls.
- **Assets**: Define textures using enums with `AssetEnum` and `TextureAssetEnum`.

## High-Performance Tips
- Use `LateTickable` for cameras to avoid jitter.
- Prefer `StatefulGameWidget` over standard `StatefulWidget` for entities that need to interact with the engine.
- Use `SpriteBatch` (if available) for large amounts of sprites.

For detailed mechanic implementations (Camera, Physics, etc.), refer to the docs in `.guides/docs/`.
</usage_guide>

<docs>
- [benchmarking](docs:goo2d:benchmarking)
- [cookbook](docs:goo2d:cookbook)
- [dartdoc](docs:goo2d:dartdoc)
- [testing](docs:goo2d:testing)
</docs>
</package>
</dotguides>
