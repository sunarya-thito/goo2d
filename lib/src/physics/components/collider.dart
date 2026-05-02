import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/goo2d.dart';

abstract class Collider extends Component
    with LifecycleListener, MultiComponent {
  Offset offset = Offset.zero;
  bool isTrigger = false;
  PhysicsMaterial material = PhysicsMaterial.defaultMaterial;
  bool isOneWay = false;
  double oneWayAngle = -1.57079632679; // -PI/2 (Up)
  double oneWayArc = 3.14159265359; // PI (180 degrees)
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
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();
  ObjectTransform? get tryTransform =>
      gameObject.tryGetComponent<ObjectTransform>();

  @override
  void onMounted() {
    game.getSystem<PhysicsSystem>()?.registerCollider(this);
  }

  @override
  void onUnmounted() {
    game.getSystem<PhysicsSystem>()?.unregisterCollider(this);
  }

  Rect get worldBounds;
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
  double alphaThreshold = 0.1;
  double tolerance = 1.0;
  bool autoGenerate = true;

  bool _isGenerating = false;
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
    final renderer = gameObject.tryGetComponent<SpriteRenderer>();
    if (renderer == null) return;
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
      game.getSystem<PhysicsSystem>()?.unregisterCollider(this);
      game.getSystem<PhysicsSystem>()?.registerCollider(this);
    } finally {
      _isGenerating = false;
    }
  }
}

class CompositeCollider extends Collider {
  final List<ColliderGeometry> shapes = [];

  @override
  Rect get worldBounds {
    if (shapes.isEmpty) return Rect.zero;
    Rect? bounds;
    for (final shape in shapes) {
      final b = shape.getWorldBounds(tryTransform, offset);
      if (bounds == null) {
        bounds = b;
      } else {
        bounds = bounds.expandToInclude(b);
      }
    }
    return bounds ?? Rect.zero;
  }

  @override
  bool containsPoint(Offset worldPoint) {
    final t = tryTransform;
    if (t == null) return false;
    for (final shape in shapes) {
      if (shape.containsPoint(worldPoint, t, offset)) return true;
    }
    return false;
  }
}

abstract class ColliderGeometry {
  Offset offset = Offset.zero;
  PhysicsMaterial material = PhysicsMaterial.defaultMaterial;
  bool isTrigger = false;
  bool isOneWay = false;
  double oneWayAngle = -1.57079632679; // -PI/2 (Up)
  double oneWayArc = 3.14159265359; // PI (180 degrees)
  Rect getWorldBounds(ObjectTransform? transform, Offset compositeOffset);
  bool containsPoint(
    Offset worldPoint,
    ObjectTransform transform,
    Offset compositeOffset,
  );
}

class CircleGeometry extends ColliderGeometry {
  double radius = 50.0;

  @override
  Rect getWorldBounds(ObjectTransform? t, Offset compositeOffset) {
    if (t == null) return Rect.zero;
    final worldCenter = t.localToWorld(offset + compositeOffset);
    final worldScale = t.scale;
    final maxScale = worldScale.dx > worldScale.dy
        ? worldScale.dx
        : worldScale.dy;
    return Rect.fromCircle(center: worldCenter, radius: radius * maxScale);
  }

  @override
  bool containsPoint(
    Offset worldPoint,
    ObjectTransform t,
    Offset compositeOffset,
  ) {
    final worldCenter = t.localToWorld(offset + compositeOffset);
    final distSq = (worldPoint - worldCenter).distanceSquared;
    final worldScale = t.scale;
    final maxScale = worldScale.dx > worldScale.dy
        ? worldScale.dx
        : worldScale.dy;
    final worldRadius = radius * maxScale;
    return distSq <= worldRadius * worldRadius;
  }
}

class BoxGeometry extends ColliderGeometry {
  Size size = const Size(100, 100);

  @override
  Rect getWorldBounds(ObjectTransform? t, Offset compositeOffset) {
    if (t == null) return Rect.zero;
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    final corners = [
      Offset(
        offset.dx + compositeOffset.dx - halfW,
        offset.dy + compositeOffset.dy - halfH,
      ),
      Offset(
        offset.dx + compositeOffset.dx + halfW,
        offset.dy + compositeOffset.dy - halfH,
      ),
      Offset(
        offset.dx + compositeOffset.dx - halfW,
        offset.dy + compositeOffset.dy + halfH,
      ),
      Offset(
        offset.dx + compositeOffset.dx + halfW,
        offset.dy + compositeOffset.dy + halfH,
      ),
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
  bool containsPoint(
    Offset worldPoint,
    ObjectTransform t,
    Offset compositeOffset,
  ) {
    final localPoint = t.worldToLocal(worldPoint);
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    final localCenter = offset + compositeOffset;
    return localPoint.dx >= localCenter.dx - halfW &&
        localPoint.dx <= localCenter.dx + halfW &&
        localPoint.dy >= localCenter.dy - halfH &&
        localPoint.dy <= localCenter.dy + halfH;
  }
}

class CapsuleGeometry extends ColliderGeometry {
  double radius = 25.0;
  double height = 100.0;
  CapsuleDirection direction = CapsuleDirection.vertical;

  @override
  Rect getWorldBounds(ObjectTransform? t, Offset compositeOffset) {
    if (t == null) return Rect.zero;
    double capOffset = (height / 2) - radius;
    if (capOffset < 0) capOffset = 0;

    final localCenter = offset + compositeOffset;
    List<Offset> centers;
    if (direction == CapsuleDirection.vertical) {
      centers = [
        Offset(localCenter.dx, localCenter.dy - capOffset),
        Offset(localCenter.dx, localCenter.dy + capOffset),
      ];
    } else {
      centers = [
        Offset(localCenter.dx - capOffset, localCenter.dy),
        Offset(localCenter.dx + capOffset, localCenter.dy),
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
  bool containsPoint(
    Offset worldPoint,
    ObjectTransform t,
    Offset compositeOffset,
  ) {
    final localPoint = t.worldToLocal(worldPoint);
    final relativePoint = localPoint - (offset + compositeOffset);

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

class PolygonGeometry extends ColliderGeometry {
  List<Offset> vertices = [];

  @override
  Rect getWorldBounds(ObjectTransform? t, Offset compositeOffset) {
    if (t == null) return Rect.zero;
    double? minX, maxX, minY, maxY;
    final localCenter = offset + compositeOffset;
    for (final v in vertices) {
      final world = t.localToWorld(v + localCenter);
      if (minX == null || world.dx < minX) minX = world.dx;
      if (maxX == null || world.dx > maxX) maxX = world.dx;
      if (minY == null || world.dy < minY) minY = world.dy;
      if (maxY == null || world.dy > maxY) maxY = world.dy;
    }
    return Rect.fromLTRB(minX ?? 0, minY ?? 0, maxX ?? 0, maxY ?? 0);
  }

  @override
  bool containsPoint(
    Offset worldPoint,
    ObjectTransform t,
    Offset compositeOffset,
  ) {
    final localPoint = t.worldToLocal(worldPoint) - (offset + compositeOffset);
    if (vertices.length < 3) return false;

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
