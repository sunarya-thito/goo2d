# Welcome to Goo2D

Goo2D is a low-level, unopinionated 2D Entity-Component-System (ECS) engine designed specifically for Flutter. 

It aims to provide a robust bridge between traditional game development paradigms (like GameObjects, Components, and Coroutines) and Flutter's reactive widget tree and RenderObject pipeline.

## Philosophy

Goo2D is built on a few core tenets:

1. **Composition over Inheritance**: Game logic should be broken down into small, reusable `Component`s that are attached to `GameObject`s.
2. **Flutter Native**: The engine doesn't try to hide Flutter. You render directly to the canvas using standard Flutter APIs, and your game objects can yield actual Flutter `Widget`s.
3. **Low-Level Primitives**: Goo2D provides the scaffolding—a scene graph, an input abstraction layer, kinematic sweep-and-prune collisions, and a ticker loop. It gives you the tools to write your own mechanics cleanly.
4. **Data-Driven Events**: Instead of massive override chains, Goo2D uses a robust `Event` broadcasting system heavily reliant on Dart `mixin`s.

## Navigating the Docs

- **[Installation](installation.md)**: How to get started and add Goo2D to your project.
- **[Architecture](architecture.md)**: Learn about `GameObject`, `Component`, Transforms, and the Event System.
- **[Input System](input.md)**: Handling keyboards and composite bindings.
- **[Collisions](collisions.md)**: Understanding `CollisionTrigger`s and screen boundaries.
- **[Lifecycle & Coroutines](lifecycle.md)**: Mastering asynchronous game logic.
- **[Tutorials](tutorials/first-game.md)**: Step-by-step guides to building a game.

---

> **⚠️ Note:** Goo2D is currently under heavy development. The API is subject to breaking changes as we finalize the core architecture. We are not currently accepting external contributions.
