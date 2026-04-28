# Guide: Writing Cookbooks

This guide outlines the mandatory structure and formatting for Goo2D cookbooks. Follow these rules strictly to ensure consistency and a high-quality learning experience for users.

## 1. Structure

Every cookbook must follow this high-level structure:

1.  **Header**: Docusaurus frontmatter (e.g., `sidebar_position`).
2.  **Intro**: A brief description of the mechanic being taught.
3.  **Live Demo**: An `iframe` pointing to the interactive demo (see [Live Demo Configuration](#live-demo-configuration) for implementation details).
4.  **Assets**: A table listing the required assets with previews and download links.
5.  **Tutorial Steps**: Granular, iterative steps.
6.  **Final Full Code**: A complete, copy-pasteable version of the entire demo.

## 2. Live Demo Configuration

The live demo is an interactive Flutter Web application hosted within an `iframe`. 

### URL Structure
The `iframe` must point to the `/goo2d/play/` path, using a URL hash (`#/`) to specify the unique route for the tutorial's example. These examples are defined in `example/lib/docs_main.dart` and deployed automatically via GitHub Actions (`.github/workflows/deploy_docs.yml`).

### Implementation
Use the following format for the `iframe`:

```html
<iframe 
  src="/goo2d/play/#/your-example-route" 
  width="100%" 
  height="400px" 
  style={{ border: 'none', borderRadius: '8px', background: '#000' }}
/>
```

**Mandatory Requirements:**
*   **Source (`src`)**: Must follow the `/goo2d/play/#/{route}` pattern.
*   **Dimensions**: `width="100%"` and `height="400px"`.
*   **Styling**: Must include `borderRadius: '8px'` and `background: '#000'` to match the documentation theme.
*   **Route Registration**: You must ensure your example is registered in the `DocsRouterApp` within `example/lib/docs_main.dart` so the hash route works correctly.

## 3. Granularity Rules

*   **Small Steps**: Break down the tutorial into the smallest logical units. Do not jump into the "finish line."
*   **Decompose Large Changes**: Make sure to break down large addition changes into smaller, manageable steps (e.g., separate defining a class from adding its properties).
*   **Logical Progression**: Ensure every class is defined (even if empty) before you ask the user to add logic to it.
*   **Break down large additions**: If a function or class change involves many lines of code (e.g. more than 5-10 lines), break it down into several smaller incremental steps instead of one large update.
*   **Separation of Concerns**: Separate boilerplate setup (Imports, main, enums) from core mechanics.

## 4. Code Formatting Rules

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

## 5. Documentation & Explanations

*   **Post-Block Explanations**: After every code block, provide a clear, descriptive explanation of what the new code does and why it is necessary.
*   **Avoid Generic Summaries**: Do not use headings like "What we did." Simply explain the function and intent of the code in 1-2 paragraphs.
*   **Technical Detail**: Explain engine-specific concepts like `dt` (delta time), `ObjectTransform`, and mixins like `Collidable`.

## 6. Asset Management

If the tutorial uses external assets:
*   Include a **Step 0: Asset Setup** that explains directory structure and `pubspec.yaml` registration.
*   Use a `GameTextures` enum in Step 1 or 2 to register textures properly using `AssetEnum` and `TextureAssetEnum`.
*   **Asset Attribution**: Must include attribution to the original creator (e.g. Kenney) and a link to the original asset page in the "Assets Used" section.


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

### DO: Explain Code and Effects
After attaching a code snippet, explain what you did or wrote and explain the effect or how it affects the game. This helps the user understand the *purpose* and *result* of the logic, not just the syntax.

**Example:**
In this step, we updated the `onUpdate` method to increment the `rotation` property by `rotationSpeed * dt`. This causes the game object to spin continuously at a constant rate regardless of the frame rate, adding a dynamic "power-up" visual effect to the sprite.

### DON'T: Plainly Describe Syntax
Don't simply restate what the code does in technical terms or provide a one-sentence summary that adds no value.

**Example:**
// BAD: Restating the code literally
"This code adds rotation speed to the transform rotation."

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

## 9. Final Review Checklist

Before finalizing your cookbook, go through this checklist to ensure it follows all guidelines:

- [ ] **Full Class Context**: Does every code block show the full class/file wrapper?
- [ ] **Explicit Highlighting**: Are all new/changed lines bracketed by `// Add this: ------` and `// --------`?
- [ ] **Granularity**: Are large changes broken down into small, iterative steps? (Max 10-15 lines per step).
- [ ] **Definition Before Use**: Are all classes, variables, and assets defined/registered before they are modified or used?
- [ ] **Meaningful Explanations**: Does every code block have a following explanation that describes both **what** was done and **how it affects the game**?
- [ ] **No Plain Descriptions**: Did you avoid short, technical descriptions that only repeat what the code says (e.g., "This adds X to Y")?
- [ ] **Live Demo Configuration**: Does the `iframe` use the correct `/goo2d/play/#/` URL and mandatory styling (8px radius, black background)?
- [ ] **Asset Management**: Are all textures registered via Enums and properly attributed to their creators?
- [ ] **Demo Parity**: Does the "Final Full Code" at the end match exactly what is required to run the tutorial's mechanic?
- [ ] **Engine Concepts**: Are engine-specific terms like `dt`, `ObjectTransform`, or `Tickable` explained when they first appear?
