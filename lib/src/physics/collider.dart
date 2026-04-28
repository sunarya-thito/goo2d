import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/goo2d.dart';

abstract class Collider extends Component with LifecycleListener {
  /// Local offset of the collider relative to the GameObject.
  Offset offset = Offset.zero;

  /// Whether this collider is a trigger.
  /// Triggers do not produce physical collisions but generate overlap events.
  bool isTrigger = false;

  /// Physical properties of the surface.
  PhysicsMaterial material = PhysicsMaterial.defaultMaterial;

  /// Bitmask for collision filtering.
  int layerMask = 0xFFFFFFFF;

  bool _wasOverlappingScreen = false;
  bool _wasFullyInsideScreen = false;

  @internal
  bool get wasOverlappingScreen => _wasOverlappingScreen;
  @internal
  set wasOverlappingScreen(bool value) => _wasOverlappingScreen = value;
  @internal
  bool get wasFullyInsideScreen => _wasFullyInsideScreen;
  @internal
  set wasFullyInsideScreen(bool value) => _wasFullyInsideScreen = value;

  /// The transform of the game object.
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();

  /// Tries to get the transform, returns null if not found.
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

  /// Returns the axis-aligned bounding box in world space.
  Rect get worldBounds;

  /// Hit test for pointer events.
  bool containsPoint(Offset worldPoint);
}

class BoxCollider extends Collider {
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

class CircleCollider extends Collider {
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

enum CapsuleDirection { vertical, horizontal }

class CapsuleCollider extends Collider {
  double radius = 25.0;
  double height = 100.0;
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

class PolygonCollider extends Collider {
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

class SpriteCollider extends PolygonCollider {
  static final Map<GameSprite, List<Offset>> _cache = {};

  /// Minimum alpha (0.0 to 1.0) to consider a pixel solid.
  double alphaThreshold = 0.1;

  /// Tolerance for polygon simplification (higher = fewer vertices).
  double tolerance = 1.0;

  /// Whether to automatically generate the polygon when the sprite is loaded.
  bool autoGenerate = true;

  bool _isGenerating = false;

  /// Pre-calculates the collision vertices for a sprite and caches them.
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
      // (The registration happened in onMounted, but vertices were empty)
      // Most physics bridges will need to be notified of the shape change.
      game.physics.unregisterCollider(this);
      game.physics.registerCollider(this);
    } finally {
      _isGenerating = false;
    }
  }
}
