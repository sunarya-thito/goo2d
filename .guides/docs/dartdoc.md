# Guide: Writing Documentation (Dartdoc)

This guide outlines the standard for writing high-quality documentation comments in Goo2D. Clear documentation is essential for maintainability and ensures that the purpose and usage of every class, method, and variable are immediately obvious.

## 1. Documentation Structure

Every documentation comment (`///`) must follow a consistent hierarchical structure to ensure clarity and professional presentation.

### Short Description (The Summary)
The first sentence of a documentation comment is the summary. It must be a single, concise sentence that explains what the element is or does.
*   **Must be on the first line.**
*   **Must end with a period.**
*   **Use the third-person singular (e.g., "Calculates," "Represents," "Handles") for methods.**

### Detailed Explanation
Following the summary, provide a more in-depth explanation in one or more paragraphs. This section should cover:
*   **Why** the element exists.
*   **How** it interacts with other parts of the engine.
*   **Side effects** or specific behaviors (e.g., "This method triggers a re-render").
*   **Edge cases** or limitations.

### Code Examples
Provide a `dart` code block to demonstrate usage. This is the most effective way to communicate how to use a complex API.
*   Use fenced code blocks with the `dart` language identifier.
### Parameters and Returns
For functions and constructors, explicitly document every parameter and the return value if it isn't obvious.
*   **Use an unordered list** for parameters, starting with the parameter name in square brackets (e.g., `* [name] Description`).
*   Describe the **intent** and **expected range/type** of each parameter to avoid ambiguity.

### See Also (Related Content)
Use a "See also" section at the end of the comment to link to related classes, methods, or external documentation that provide additional context.
*   Format: `/// See also:` followed by an unordered list of links.
*   Use this for complex systems where multiple components interact.

---

## 2. Example Implementation

Here is an example of a properly documented class method:

```dart
/// Calculates the collision response between two [GameObject] instances.
///
/// This method uses the [ObjectTransform] of both objects to determine the
/// overlap depth and the normal vector of the collision. It then applies
/// a restorative force based on the physics material properties.
///
/// If either object is missing a [Collider] component, the method returns
/// [Offset.zero] and no force is applied.
///
/// ```dart
/// final response = physicsSystem.calculateResponse(objA, objB);
/// if (response != Offset.zero) {
///   objA.transform.position += response;
/// }
/// ```
///
/// * [other] The game object to check for collision against.
/// * [dt] The delta time of the current frame, used to scale impulses.
///
/// Returns an [Offset] representing the displacement vector required to resolve the overlap.
///
/// See also:
/// * [Collider] for defining collision shapes.
/// * [PhysicsMaterial] for restorative force coefficients.
Offset calculateResponse(GameObject other, double dt) {
  // ... implementation ...
}
```

---

## 3. Handling Parameters and Constructors

Ambiguity in parameters leads to bugs. When documenting parameters:
*   **Units**: Always specify units (e.g., "pixels," "seconds," "radians").
*   **Nullability**: Explicitly state if a parameter can be null and what happens in that case.
*   **Default Behavior**: Mention the default behavior if the parameter is optional.

**Example for a Constructor:**
```dart
/// Creates a new [SpriteRenderer] with the specified [texture].
///
/// * [texture] The [TextureAsset] to be rendered. Must not be null.
/// * [color] The tint color to apply to the sprite. Defaults to [Colors.white].
/// * [opacity] The transparency level from 0.0 (transparent) to 1.0 (opaque).
SpriteRenderer({
  required this.texture,
  this.color = Colors.white,
  this.opacity = 1.0,
});
```

---

## 4. Dos and Don'ts

### DO: Use Square Brackets for Links
Use `[ClassName]` or `[methodName]` to create links in the generated documentation. This helps users navigate the API.

### DON'T: Use Redundant Phrases
Avoid starting with "This class is..." or "This function is used to...". Start directly with the action or description.
*   **Bad**: `/// This function adds a component to the object.`
*   **Good**: `/// Adds a component to the object.`

### DON'T: Assume Behavior Based on Name
Never write documentation based solely on the identifier name. You **must** examine the full implementation of the method or class to understand side effects, edge cases, and actual logic.
*   **Bad**: Documenting `reset()` as "Resets the state" without realizing it also triggers a network sync or clears a cache.
*   **Good**: Documenting `reset()` after verifying it clears the internal buffer and notifies all registered listeners.

### DO: Document Side Effects
If a property setter or a method modifies global state or has significant side effects, it **must** be mentioned.

### DON'T: Leave Parameters Undocumented
If a function takes multiple parameters, don't just document one. Every argument should have a description if its purpose isn't strictly literal (like a simple ID).

### DO: Use Markdown for Formatting
Use `**bold**`, `*italics*`, and backticks for `code` to make the documentation readable.

### DO: Escape Angle Brackets
Always escape angle brackets (`<` and `>`) if they are not inside a code block or backticks. Use `&lt;` and `&gt;` to prevent them from being interpreted as HTML tags.
*   **Bad**: `/// Returns a List<String> of names.`
*   **Good**: `/// Returns a List&lt;String&gt; of names.` or `/// Returns a [List] of names.`

### DONT: Change implementation code
Do NOT touch implementation code, leave it as it is, only add dartdoc. If you notice an error on the code, do NOT change it! It is not your responsible.

---

## 5. Final Review Checklist

Before finishing your documentation, verify it against this list:

- [ ] **Summary Sentence**: Does the first line end with a period and provide a concise summary?
- [ ] **In-depth Explanation**: Does the doc has in-depth explanation after the summary sentence in the first line?
- [ ] **No Redundancy**: Did you avoid starting with filler phrases like "This class is..." or "This function is used to..."?
- [ ] **Depth**: Is there a paragraph following the summary explaining the "why" and "how"?
- [ ] **Code Example**: Does every non-trivial class or method include a `dart` code block example?
- [ ] **Parameter Clarity**: Is every parameter documented in an **unordered list** (`* [name]`) with its intent, units, and nullability?
- [ ] **No Missing Parameters**: Are all arguments in the function/constructor documented?
- [ ] **Ambiguity Check**: Could a user misunderstand the purpose of any argument? (e.g., is "angle" in degrees or radians?)
- [ ] **Links**: Are related classes and methods wrapped in square brackets?
- [ ] **Tone**: Is the tone professional and direct?
- [ ] **Return Values**: Is the return value's meaning and potential edge cases (like null or empty) documented?
- [ ] **Formatting**: Are code blocks and markdown elements used correctly for readability?
- [ ] **Angle Brackets**: Are all `<` and `>` escaped as `&lt;` and `&gt;` (unless in backticks or code blocks)?
- [ ] **See Also**: If relevant, did you include a "See also:" section with links to related content?
- [ ] **Implementation-Based**: Did you verify the actual implementation logic instead of assuming behavior based on the name?
- [ ] **Side Effects**: Are significant side effects or state changes explicitly mentioned?
- [ ] **No Code Changed**: Did you modify any implementation code? If so, revert those changes.