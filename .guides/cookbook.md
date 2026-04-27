# Guide: Writing Cookbooks

This guide outlines the mandatory structure and formatting for Goo2D cookbooks. Follow these rules strictly to ensure consistency and a high-quality learning experience for users.

## 1. Structure

Every cookbook must follow this high-level structure:

1.  **Header**: Docusaurus frontmatter (e.g., `sidebar_position`).
2.  **Intro**: A brief description of the mechanic being taught.
3.  **Live Demo**: An `iframe` pointing to the interactive demo.
4.  **Assets**: A table listing the required assets with previews and download links.
5.  **Tutorial Steps**: Granular, iterative steps.
6.  **Final Full Code**: A complete, copy-pasteable version of the entire demo.

## 2. Granularity Rules

*   **Small Steps**: Break down the tutorial into the smallest logical units. Do not jump into the "finish line."
*   **Decompose Large Changes**: Make sure to break down large addition changes into smaller, manageable steps (e.g., separate defining a class from adding its properties).
*   **Logical Progression**: Ensure every class is defined (even if empty) before you ask the user to add logic to it.
*   **Break down large additions**: If a function or class change involves many lines of code (e.g. more than 5-10 lines), break it down into several smaller incremental steps instead of one large update.
*   **Separation of Concerns**: Separate boilerplate setup (Imports, main, enums) from core mechanics.

## 3. Code Formatting Rules

### Full Class Context
**NEVER** show a partial function or a loose snippet. Every code block must contain the **full class** (or full file for boilerplate) so the user understands exactly where the code belongs.

### Highlighting Changes
Mark all new or updated lines of code with specific comment markers:
*   Start the highlighted section with `// Add this: ------`.
*   End the highlighted section with `// --------`.

Example:
```dart
class ProjectileBehavior extends Behavior with Tickable {
  // Add this: ------
  Offset velocity = const Offset(3.0, 2.0);
  // ----------------

  @override
  void onUpdate(double dt) {
    // Add this: ------
    final transform = getComponent<ObjectTransform>();
    transform.position += velocity * dt;
    // ----------------
  }
}
```

## 4. Documentation & Explanations

*   **Post-Block Explanations**: After every code block, provide a clear, descriptive explanation of what the new code does and why it is necessary.
*   **Avoid Generic Summaries**: Do not use headings like "What we did." Simply explain the function and intent of the code in 1-2 paragraphs.
*   **Technical Detail**: Explain engine-specific concepts like `dt` (delta time), `ObjectTransform`, and mixins like `Collidable`.

## 5. Asset Management

If the tutorial uses external assets:
*   Include a **Step 0: Asset Setup** that explains directory structure and `pubspec.yaml` registration.
*   Use a `GameTextures` enum in Step 1 or 2 to register textures properly using `AssetEnum` and `TextureAssetEnum`.
*   **Asset Attribution**: Must include attribution to the original creator (e.g. Kenney) and a link to the original asset page in the "Assets Used" section.

## 6. Checklist for Final Review

- [ ] Does every step show a full class/file?
- [ ] Are all new additions bracketed by `// Add this: ------` and `// --------`?
- [ ] Is there an explanation after every code block?
- [ ] Are classes defined before they are used or modified?
- [ ] Does the "Final Full Code" at the end match the cumulative result of all steps?

## 7. Dos and Don'ts

### DO: Show Full Class Context
Always show the class wrapper so the user knows exactly where the code goes.

**Example:**
```dart
class MyBehavior extends Behavior with Tickable {
  // Add this: ------
  double speed = 5.0;
  // --------

  @override
  void onUpdate(double dt) {}
}
```

### DON'T: Show Loose Snippets
Never show just a few lines of code without their surrounding class or method context.

**Example:**
```dart
// BAD: Where does this go? Which class?
double speed = 5.0;
transform.position += velocity * dt;
```

---

### DO: Break Down Complex Logic
If a method has several steps (e.g., bounds checking + velocity flipping), show them in separate tutorial steps.

**Example:**
*   Step 10: Calculate screen boundaries.
*   Step 11: Implement horizontal bounce logic.
*   Step 12: Implement vertical bounce logic.

### DON'T: Jump to the "Finish Line"
Don't provide the complete, complex function in a single step. This is overwhelming and obscures the logic.

**Example:**
*   Step 10: Here is the full 30-line `onCollision` method with math, randomization, and color cycling. (Spoon-feeding)

---

### DO: Use Explicit Highlighting
Use the mandatory markers to point exactly to what changed.

**Example:**
```dart
// Add this: ------
final transform = getComponent<ObjectTransform>();
// --------
```

### DON'T: Use Implicit Changes
Don't just provide a block of code and expect the user to find the difference.

**Example:**
```dart
// BAD: User has to hunt for what changed since Step 4
class MyBehavior extends Behavior with Tickable {
  double speed = 5.0;
  @override
  void onUpdate(double dt) {
    transform.position += velocity * dt;
  }
}
```

---

### DO: Define Before Use
Ensure a class is introduced as an empty skeleton before properties or logic are added to it.

**Example:**
*   Step 5: Create empty `MyBehavior` class.
*   Step 6: Add `velocity` field to `MyBehavior`.

### DON'T: Reference Non-Existent Classes
Don't ask the user to "Add this to `MyBehavior`" if the class wasn't created in a previous step.

**Example:**
*   Step 1: Boilerplate.
*   Step 2: "Add `velocity` to `MyBehavior`" (Error: `MyBehavior` class was never created in Step 1).

---

### DO: Break Large Additions Into Smaller Steps
Break down a large block of logic into incremental updates. This allows you to explain the purpose of each individual part clearly.

**Example:**
```dart
class ProjectileBehavior extends Behavior with Tickable, Collidable {
  // ... existing code ...
  @override
  void onCollision(CollisionEvent event) {
    // Add this: ------
    final diff = transform.position - otherPos;
    if (diff.dx.abs() > diff.dy.abs()) {
      // Logic...
    }
    // --------
  }
}
```

### DON'T: Add Large Blocks At Once
Adding 20+ lines of code in a single step makes the "purpose" explanation vague and harder for the user to digest.

**Example:**
```dart
// BAD: Adding massive amounts of unrelated logic in one go
@override
void onCollision(CollisionEvent event) {
  final transform = getComponent<ObjectTransform>();
  final otherPos = event.other.gameObject.getComponent<ObjectTransform>().position;
  final diff = transform.position - otherPos;
  final random = math.Random();
  if (diff.dx.abs() > diff.dy.abs()) {
    if ((velocity.dx > 0 && diff.dx < 0) || (velocity.dx < 0 && diff.dx > 0)) {
      velocity = Offset(-velocity.dx, velocity.dy + (random.nextDouble() - 0.5) * 0.5);
      transform.position += Offset(velocity.dx.sign * 0.1, 0);
    }
  } else {
    if ((velocity.dy > 0 && diff.dy < 0) || (velocity.dy < 0 && diff.dy > 0)) {
      velocity = Offset(velocity.dx + (random.nextDouble() - 0.5) * 0.5, -velocity.dy);
      transform.position += Offset(0, velocity.dy.sign * 0.1);
    }
  }
  velocity = (velocity / velocity.distance) * 3.0;
  hitCount = (hitCount + 1) % colors.length;
  getComponent<SpriteRenderer>().color = colors[hitCount];
}
```

---

## 8. Step Example

Here is how a single tutorial step should look in your markdown file:

### 11. Implementing the Bounce Logic
Now let's make the ship bounce properly when it hits something.

```dart
class ProjectileBehavior extends Behavior with Tickable, Collidable {
  Offset velocity = const Offset(3.0, 2.0);

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    transform.position += velocity * dt;
  }

  @override
  void onCollision(CollisionEvent event) {
    // Add this: ------
    final transform = getComponent<ObjectTransform>();
    final otherPos = event.other.gameObject.getComponent<ObjectTransform>().position;
    final diff = transform.position - otherPos;

    if (diff.dx.abs() > diff.dy.abs()) {
      if ((velocity.dx > 0 && diff.dx < 0) || (velocity.dx < 0 && diff.dx > 0)) {
        velocity = Offset(-velocity.dx, velocity.dy);
        transform.position += Offset(velocity.dx.sign * 0.1, 0); 
      }
    }
    // ----------------
  }
}
```

We calculate the difference between our position and the obstacle's position to determine the collision axis. We only flip the velocity if we are moving **towards** the other object. Additionally, we add a small `0.1` unit "push" to immediately separate the hitboxes, preventing them from staying stuck together in a loop.
