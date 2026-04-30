import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/goo2d.dart';

/// The base class for all physical shapes in the Goo2D engine.
/// 
/// Colliders define the volume of a [GameObject] for the purpose of 
/// physical collisions and trigger events. They must be attached to 
/// a [GameObject] that has an [ObjectTransform] to be correctly positioned 
/// in the [PhysicsWorld].
/// 
/// ```dart
/// class MyBouncyBall extends GameObject {
///   @override
///   void onAwake() {
///     addComponent(CircleCollider()..radius = 50);
///     addComponent(Rigidbody()..type = RigidbodyType.dynamic);
///   }
/// }
/// ```
abstract class Collider extends Component with LifecycleListener {
  /// The local offset of the collider relative to its parent center.
  /// 
  /// This allows you to shift the collision volume without moving the 
  /// entire [GameObject]. Useful for offset centers of mass or 
  /// multi-collider objects.
  Offset offset = Offset.zero;

  /// If true, this collider will not block other objects.
  /// 
  /// Triggers are used for region detection, such as power-ups, 
  /// area-of-effect zones, or checkpoint markers. They do not participate 
  /// in physical resolution but still generate collision events.
  bool isTrigger = false;

  /// The material properties of the collider surface.
  /// 
  /// Defines how the surface interacts with others in terms of friction 
  /// (sliding resistance) and bounciness (energy restitution).
  PhysicsMaterial material = PhysicsMaterial.defaultMaterial;

  /// A bitmask used to determine which other objects this collider can hit.
  /// 
  /// The engine performs a bitwise AND between the [layerMask] of two 
  /// objects. If the result is non-zero, they can collide. This is the 
  /// primary way to optimize physics by skipping unnecessary checks.
  /// 
  /// ```dart
  /// collider.layerMask = 0x1; // Only collide with layer 1
  /// ```
  int layerMask = 0xFFFFFFFF;

  bool _wasOverlappingScreen = false;
  bool _wasFullyInsideScreen = false;

  /// Internal tracking for screen visibility events.
  /// 
  /// This state is managed by the [PhysicsSystem] to determine when 
  /// a collider enters or exits the viewport.
  @internal
  bool get wasOverlappingScreen => _wasOverlappingScreen;
  
  /// Internal tracking for screen visibility events.
  /// 
  /// * [value]: Whether the collider is currently overlapping the screen.
  @internal
  set wasOverlappingScreen(bool value) => _wasOverlappingScreen = value;
  
  /// Internal tracking for screen visibility events.
  /// 
  /// This state is used to trigger onWillEnterScreen and onWillExitScreen 
  /// lifecycle events.
  @internal
  bool get wasFullyInsideScreen => _wasFullyInsideScreen;
  
  /// Internal tracking for screen visibility events.
  /// 
  /// * [value]: Whether the collider is fully contained within the screen.
  @internal
  set wasFullyInsideScreen(bool value) => _wasFullyInsideScreen = value;

  /// Retrieves the transform component of the parent object.
  /// 
  /// Accessing this property will throw an error if the [GameObject] 
  /// does not have an [ObjectTransform]. Use [tryTransform] for safe access.
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();

  /// Safely attempts to retrieve the transform component.
  /// 
  /// Returns null if the parent [GameObject] lacks an [ObjectTransform], 
  /// allowing for graceful degradation in non-physical contexts.
  ObjectTransform? get tryTransform =>
      gameObject.tryGetComponent<ObjectTransform>();

  @override
  void onMounted() {
    game.physics.registerCollider(this);
  }

  @override
  void onUnmounted() {
    game.physics.unregisterCollider(this);
  }

  /// The Axis-Aligned Bounding Box (AABB) of the collider in world space.
  /// 
  /// This rectangle represents the minimum and maximum extents of the shape 
  /// after taking into account the object's position, rotation, and scale.
  Rect get worldBounds;

  /// Checks if a specific point in world space is inside the collider.
  /// 
  /// This is used for high-level hit testing, such as mouse clicks or 
  /// targeted spell effects. The implementation varies by collider type.
  /// 
  /// * [worldPoint]: The position to test in absolute world coordinates.
  bool containsPoint(Offset worldPoint);
}

/// A rectangular physical volume.
/// 
/// Box colliders are the most common shape used for platforms, walls, and 
/// simple props. They are computationally efficient because their overlap 
/// checks involve simple coordinate comparisons.
/// 
/// See also:
/// * [CircleCollider] for spherical objects.
/// * [CapsuleCollider] for characters.
/// 
/// ```dart
/// final ground = GameObject()
///   ..addComponent(BoxCollider()..size = Size(1000, 20));
/// ```
class BoxCollider extends Collider {
  /// The width and height of the box in local world units.
  /// 
  /// The size is centered on the [offset]. If the parent [ObjectTransform] 
  /// is scaled, this size will be multiplied by that scale in world space.
  Size size = const Size(100, 100);

  @override
  Rect get worldBounds {
    final t = tryTransform;
    if (t == null) return Rect.zero;
    final halfW = size.width / 2;
    final halfH = size.height / 2;

    // Corners in local space
    final corners = [
      Offset(offset.dx - halfW, offset.dy - halfH),
      Offset(offset.dx + halfW, offset.dy - halfH),
      Offset(offset.dx - halfW, offset.dy + halfH),
      Offset(offset.dx + halfW, offset.dy + halfH),
    ];

    double? minX, maxX, minY, maxY;
    for (final corner in corners) {
      final world = t.localToWorld(corner);
      if (minX == null || world.dx < minX) minX = world.dx;
      if (maxX == null || world.dx > maxX) maxX = world.dx;
      if (minY == null || world.dy < minY) minY = world.dy;
      if (maxY == null || world.dy > maxY) maxY = world.dy;
    }

    return Rect.fromLTRB(minX ?? 0, minY ?? 0, maxX ?? 0, maxY ?? 0);
  }

  @override
  bool containsPoint(Offset worldPoint) {
    final t = tryTransform;
    if (t == null) return false;
    final localPoint = t.worldToLocal(worldPoint);
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    return localPoint.dx >= offset.dx - halfW &&
        localPoint.dx <= offset.dx + halfW &&
        localPoint.dy >= offset.dy - halfH &&
        localPoint.dy <= offset.dy + halfH;
  }
}

/// A circular physical volume.
/// 
/// Circle colliders are ideal for projectiles, spheres, and characters that 
/// need to roll or have isotropic collision behavior. They are the most 
/// performance-efficient collider for narrow-phase detection.
/// 
/// See also:
/// * [BoxCollider] for rectangular shapes.
/// 
/// ```dart
/// final bullet = GameObject()
///   ..addComponent(CircleCollider()..radius = 10);
/// ```
class CircleCollider extends Collider {
  /// The radius of the circle in local world units.
  /// 
  /// The effective world-space radius will be [radius] multiplied by the 
  /// maximum scale component of the parent [ObjectTransform].
  double radius = 50.0;

  @override
  Rect get worldBounds {
    final t = tryTransform;
    if (t == null) return Rect.zero;
    final worldCenter = t.localToWorld(offset);
    final worldScale = t.scale;
    final maxScale = worldScale.dx > worldScale.dy
        ? worldScale.dx
        : worldScale.dy;
    final worldRadius = radius * maxScale;
    return Rect.fromCircle(center: worldCenter, radius: worldRadius);
  }

  @override
  bool containsPoint(Offset worldPoint) {
    final t = tryTransform;
    if (t == null) return false;
    final worldCenter = t.localToWorld(offset);
    final distSq = (worldPoint - worldCenter).distanceSquared;

    final worldScale = t.scale;
    final maxScale = worldScale.dx > worldScale.dy
        ? worldScale.dx
        : worldScale.dy;
    final worldRadius = radius * maxScale;

    return distSq <= worldRadius * worldRadius;
  }
}

/// The orientation of a [CapsuleCollider].
/// 
/// This defines whether the pill shape is elongated along the vertical (Y) 
/// or horizontal (X) axis relative to the [GameObject]'s local rotation.
enum CapsuleDirection { 
  /// Stretches along the Y axis.
  vertical, 
  
  /// Stretches along the X axis.
  horizontal 
}

/// A pill-shaped physical volume.
/// 
/// Capsules are the industry-standard choice for character controllers because 
/// they slide smoothly over step-up geometry (like stairs) and prevent 
/// "catching" on sharp corners that would trap a [BoxCollider].
/// 
/// See also:
/// * [CircleCollider] for simple round objects.
/// 
/// ```dart
/// final player = GameObject()
///   ..addComponent(CapsuleCollider()
///     ..radius = 20
///     ..height = 80
///     ..direction = CapsuleDirection.vertical);
/// ```
class CapsuleCollider extends Collider {
  /// The radius of the hemispherical caps at each end.
  /// 
  /// The width/thickness of the capsule is twice this value.
  double radius = 25.0;
  
  /// The total length of the capsule from cap-tip to cap-tip.
  /// 
  /// If the [height] is less than or equal to `radius * 2`, the collider 
  /// effectively becomes a [CircleCollider].
  double height = 100.0;
  
  /// The orientation of the capsule's primary axis.
  /// 
  /// Determines whether the capsule stretches along the local X or Y axis.
  CapsuleDirection direction = CapsuleDirection.vertical;

  @override
  Rect get worldBounds {
    final t = tryTransform;
    if (t == null) return Rect.zero;
    double capOffset = (height / 2) - radius;
    if (capOffset < 0) capOffset = 0;

    List<Offset> centers;
    if (direction == CapsuleDirection.vertical) {
      centers = [
        Offset(offset.dx, offset.dy - capOffset),
        Offset(offset.dx, offset.dy + capOffset),
      ];
    } else {
      centers = [
        Offset(offset.dx - capOffset, offset.dy),
        Offset(offset.dx + capOffset, offset.dy),
      ];
    }

    double? minX, maxX, minY, maxY;
    for (final p in centers) {
      final world = t.localToWorld(p);
      final worldScale = t.scale;
      final worldR =
          radius *
          (worldScale.dx > worldScale.dy ? worldScale.dx : worldScale.dy);

      final b = Rect.fromCircle(center: world, radius: worldR);
      if (minX == null || b.left < minX) minX = b.left;
      if (maxX == null || b.right > maxX) maxX = b.right;
      if (minY == null || b.top < minY) minY = b.top;
      if (maxY == null || b.bottom > maxY) maxY = b.bottom;
    }

    return Rect.fromLTRB(minX ?? 0, minY ?? 0, maxX ?? 0, maxY ?? 0);
  }

  @override
  bool containsPoint(Offset worldPoint) {
    final t = tryTransform;
    if (t == null) return false;
    final localPoint = t.worldToLocal(worldPoint);
    final relativePoint = localPoint - offset;

    double halfHeight = (height - radius * 2) / 2;
    if (halfHeight < 0) halfHeight = 0;

    double distSq;
    if (direction == CapsuleDirection.vertical) {
      double y = relativePoint.dy.clamp(-halfHeight, halfHeight);
      distSq = (relativePoint - Offset(0, y)).distanceSquared;
    } else {
      double x = relativePoint.dx.clamp(-halfHeight, halfHeight);
      distSq = (relativePoint - Offset(x, 0)).distanceSquared;
    }

    return distSq <= radius * radius;
  }
}

/// A collider defined by an arbitrary list of [vertices].
/// 
/// [PolygonCollider] supports concave shapes and is ideal for 
/// complex static geometry like rocky terrain or room outlines. 
/// Vertices should be defined in local space relative to [offset].
/// 
/// ```dart
/// final triangle = GameObject()
///   ..addComponent(PolygonCollider()..vertices = [
///     Offset(0, -50), Offset(50, 50), Offset(-50, 50)
///   ]);
/// ```
class PolygonCollider extends Collider {
  /// The local vertices defining the polygon shape.
  /// 
  /// The polygon is automatically closed by connecting the last vertex 
  /// to the first. Vertices should be provided in clockwise or 
  /// counter-clockwise order.
  List<Offset> vertices = [];

  @override
  Rect get worldBounds {
    final t = tryTransform;
    if (t == null) return Rect.zero;
    double? minX, maxX, minY, maxY;
    for (final v in vertices) {
      final world = t.localToWorld(v + offset);
      if (minX == null || world.dx < minX) minX = world.dx;
      if (maxX == null || world.dx > maxX) maxX = world.dx;
      if (minY == null || world.dy < minY) minY = world.dy;
      if (maxY == null || world.dy > maxY) maxY = world.dy;
    }
    return Rect.fromLTRB(minX ?? 0, minY ?? 0, maxX ?? 0, maxY ?? 0);
  }

  @override
  bool containsPoint(Offset worldPoint) {
    final t = tryTransform;
    if (t == null) return false;
    final localPoint = t.worldToLocal(worldPoint) - offset;
    if (vertices.length < 3) return false;

    // Ray casting algorithm for point in polygon
    bool inside = false;
    for (int i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      if (((vertices[i].dy > localPoint.dy) !=
              (vertices[j].dy > localPoint.dy)) &&
          (localPoint.dx <
              (vertices[j].dx - vertices[i].dx) *
                      (localPoint.dy - vertices[i].dy) /
                      (vertices[j].dy - vertices[i].dy) +
                  vertices[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// A specialized [PolygonCollider] that generates its shape from a [GameSprite].
/// 
/// This component analyzes the alpha channel of a sprite to find 
/// its contours and automatically generates a matching polygon. This 
/// is extremely useful for pixel-perfect collisions on complex character 
/// sprites without manual vertex placement.
/// 
/// ```dart
/// final hero = GameObject()
///   ..addComponent(SpriteRenderer(heroSprite))
///   ..addComponent(SpriteCollider()..tolerance = 2.0);
/// ```
class SpriteCollider extends PolygonCollider {
  static final Map<GameSprite, List<Offset>> _cache = {};

  /// Minimum alpha value (0.0 to 1.0) required to consider a pixel "solid".
  /// 
  /// Lower values make the collider more sensitive to semi-transparent 
  /// edge pixels.
  double alphaThreshold = 0.1;

  /// Tolerance for the Ramer-Douglas-Peucker simplification algorithm.
  /// 
  /// Higher values result in fewer vertices and better performance, 
  /// but less accurate shapes. A value of 1.0 is usually a good balance.
  double tolerance = 1.0;

  /// If true, the polygon is generated automatically as soon as 
  /// the sprite is loaded.
  /// 
  /// This requires a [SpriteRenderer] to be present on the same [GameObject].
  bool autoGenerate = true;

  bool _isGenerating = false;

  /// Generates and caches collision vertices for a specific [sprite].
  /// 
  /// This method decodes the sprite texture, traces its edges, 
  /// simplifies the resulting path, and scales it into world units based 
  /// on the sprite's PPU and pivot.
  /// 
  /// * [sprite]: The sprite to analyze.
  /// * [alphaThreshold]: Transparency cutoff for solidity.
  /// * [tolerance]: Simplification aggressive level.
  static Future<List<Offset>> bake(
    GameSprite sprite, {
    double alphaThreshold = 0.1,
    double tolerance = 1.0,
  }) async {
    if (_cache.containsKey(sprite)) return _cache[sprite]!;

    if (!sprite.texture.isLoaded) {
      await sprite.texture.load();
    }

    final pixels = sprite.texture.getPixels32();
    final rect = sprite.rect;
    final ppu = sprite.pixelsPerUnit;
    final pivot = sprite.pivotOffset;

    // Generate vertices from the sprite's alpha channel.
    final vertices = SpritePolygonGenerator.generate(
      pixels: pixels,
      width: sprite.texture.width,
      height: sprite.texture.height,
      sourceRect: rect,
      alphaThreshold: alphaThreshold,
      tolerance: tolerance,
    );

    // Convert pixel coordinates to local world units relative to pivot
    final worldVertices = vertices.map((v) {
      return Offset(
        (v.dx - rect.left - pivot.dx) / ppu,
        (v.dy - rect.top - pivot.dy) / ppu,
      );
    }).toList();

    _cache[sprite] = worldVertices;
    return worldVertices;
  }

  @override
  void onMounted() {
    super.onMounted();
    if (autoGenerate) {
      _tryGenerate();
    }
  }

  /// Asynchronously triggers the baking process.
  /// 
  /// Locates the [SpriteRenderer], calls [bake], and updates the 
  /// [PhysicsSystem] with the new vertices.
  void _tryGenerate() async {
    if (_isGenerating) return;
    final renderer = gameObject.getComponent<SpriteRenderer>();
    final sprite = renderer.sprite;
    if (sprite == null) return;

    _isGenerating = true;
    try {
      vertices = await bake(
        sprite,
        alphaThreshold: alphaThreshold,
        tolerance: tolerance,
      );
      // Trigger a physics update if needed
      game.physics.unregisterCollider(this);
      game.physics.registerCollider(this);
    } finally {
      _isGenerating = false;
    }
  }
}
