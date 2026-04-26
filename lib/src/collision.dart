import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

mixin Collidable implements EventListener {
  void onCollision(CollisionEvent collision);
}

class CollisionEvent extends Event<Collidable> {
  final CollisionTrigger self;
  final CollisionTrigger other;
  final Rect intersectionRect;

  const CollisionEvent(this.self, this.other, this.intersectionRect);

  @override
  void dispatch(Collidable listener) {
    listener.onCollision(this);
  }
}

abstract class CollisionTrigger extends Component with LifecycleListener {
  /// The transform of the game object, or `null` if none is attached.
  /// When absent, the collider operates in local space (identity transform).
  ObjectTransform? get transform =>
      gameObject.tryGetComponent<ObjectTransform>();

  /// Bitmask for collision filtering.
  /// Two colliders interact only if `(a.layerMask & b.layerMask) != 0`.
  /// Default `0xFFFFFFFF` means "collide with everything".
  int layerMask = 0xFFFFFFFF;

  /// Local-space bounds (axis-aligned bounding box of the shape before
  /// any transform is applied).
  Rect get bounds;

  /// Whether the collider contains a point in local space.
  bool contains(Offset localPoint);

  /// Whether this collider interacts with another.
  /// Broad-phase (AABB) is already checked before this is called.
  bool collidesWith(CollisionTrigger other) {
    // If either is an oval, do circle-based distance check (narrow phase)
    if (this is OvalCollisionTrigger && other is OvalCollisionTrigger) {
      final a = this as OvalCollisionTrigger;
      final b = other;
      final centerA = a.transform?.localToWorld(a.center) ?? a.center;
      final centerB = b.transform?.localToWorld(b.center) ?? b.center;
      final dx = centerA.dx - centerB.dx;
      final dy = centerA.dy - centerB.dy;
      final distSq = dx * dx + dy * dy;

      // Approximate as circles using max radius
      final rA = a.radiusX > a.radiusY ? a.radiusX : a.radiusY;
      final rB = b.radiusX > b.radiusY ? b.radiusX : b.radiusY;
      final rSum = rA + rB;
      return distSq <= rSum * rSum;
    }

    // Default to AABB (already checked by caller, but for completeness)
    return true;
  }

  bool _wasOverlappingScreen = false;
  bool _wasFullyInsideScreen = false;

  @override
  void onMounted() {
    game.collision.register(this);
  }

  @override
  void onUnmounted() {
    game.collision.unregister(this);
  }

  Rect? _cachedWorldBounds;
  int _cachedVersion = -1;

  /// Axis-aligned bounding box in world space.
  /// Cached until the transform changes (tracked via [ObjectTransform.version]).
  /// When no transform is present, returns local [bounds] directly.
  Rect get worldBounds {
    final t = transform;
    if (t == null) return bounds;
    final v = t.version;
    if (_cachedWorldBounds != null && _cachedVersion == v) {
      return _cachedWorldBounds!;
    }
    _cachedWorldBounds = _calculateWorldBounds(t);
    _cachedVersion = v;
    return _cachedWorldBounds!;
  }

  Rect _calculateWorldBounds(ObjectTransform transform);
}

class OvalCollisionTrigger extends CollisionTrigger {
  double radiusX = 0;
  double radiusY = 0;
  Offset center = Offset.zero;

  @override
  Rect get bounds =>
      Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2);

  @override
  Rect _calculateWorldBounds(ObjectTransform transform) {
    // Transform the 4 corners of the local bounding box to find the world AABB.
    final b = bounds;
    final tl = transform.localToWorld(b.topLeft);
    final tr = transform.localToWorld(b.topRight);
    final bl = transform.localToWorld(b.bottomLeft);
    final br = transform.localToWorld(b.bottomRight);

    final minX = _min4(tl.dx, tr.dx, bl.dx, br.dx);
    final maxX = _max4(tl.dx, tr.dx, bl.dx, br.dx);
    final minY = _min4(tl.dy, tr.dy, bl.dy, br.dy);
    final maxY = _max4(tl.dy, tr.dy, bl.dy, br.dy);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool contains(Offset localPoint) {
    if (radiusX <= 0 || radiusY <= 0) return false;

    // Ellipse hit test in local space: ((x-cx)/rx)^2 + ((y-cy)/ry)^2 <= 1
    final dx = (localPoint.dx - center.dx) / radiusX;
    final dy = (localPoint.dy - center.dy) / radiusY;
    return dx * dx + dy * dy <= 1.0;
  }
}

class BoxCollisionTrigger extends CollisionTrigger {
  Rect rect = Rect.zero;

  @override
  Rect get bounds => rect;

  @override
  Rect _calculateWorldBounds(ObjectTransform transform) {
    final tl = transform.localToWorld(rect.topLeft);
    final tr = transform.localToWorld(rect.topRight);
    final bl = transform.localToWorld(rect.bottomLeft);
    final br = transform.localToWorld(rect.bottomRight);

    final minX = _min4(tl.dx, tr.dx, bl.dx, br.dx);
    final maxX = _max4(tl.dx, tr.dx, bl.dx, br.dx);
    final minY = _min4(tl.dy, tr.dy, bl.dy, br.dy);
    final maxY = _max4(tl.dy, tr.dy, bl.dy, br.dy);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool contains(Offset localPoint) {
    return rect.contains(localPoint);
  }
}

double _min4(double a, double b, double c, double d) {
  double m = a;
  if (b < m) m = b;
  if (c < m) m = c;
  if (d < m) m = d;
  return m;
}

double _max4(double a, double b, double c, double d) {
  double m = a;
  if (b > m) m = b;
  if (c > m) m = c;
  if (d > m) m = d;
  return m;
}

void internalUpdateScreenState(
  CollisionTrigger collider, {
  required bool overlapping,
  required bool fullyInside,
}) {
  collider._wasOverlappingScreen = overlapping;
  collider._wasFullyInsideScreen = fullyInside;
}

bool internalGetWasOverlapping(CollisionTrigger collider) =>
    collider._wasOverlappingScreen;
bool internalGetWasFullyInside(CollisionTrigger collider) =>
    collider._wasFullyInsideScreen;
