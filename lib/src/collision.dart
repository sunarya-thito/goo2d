import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

// -----------------------------------------------------------------------------
// Collision events
// -----------------------------------------------------------------------------

mixin Collidable implements EventListener {
  void onCollision(CollisionEvent collision);
}

class CollisionEvent extends Event<Collidable> {
  final Collider self;
  final Collider other;
  final Rect intersectionRect;

  const CollisionEvent(this.self, this.other, this.intersectionRect);

  @override
  void dispatch(Collidable listener) {
    listener.onCollision(this);
  }
}

// -----------------------------------------------------------------------------
// Collider base
// -----------------------------------------------------------------------------

abstract class Collider extends Component with LifecycleListener {
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

  // ---------------------------------------------------------------------------
  // Self-registration — colliders register on mount, no collection needed
  // ---------------------------------------------------------------------------

  /// All active colliders. Maintained incrementally via mount/unmount.
  static final List<Collider> _active = [];

  static Iterable<Collider> get active => _active;

  bool _wasOverlappingScreen = false;
  bool _wasFullyInsideScreen = false;

  @override
  void onMounted() {
    _active.add(this);
  }

  @override
  void onUnmounted() {
    _active.remove(this);
  }

  // ---------------------------------------------------------------------------
  // World bounds caching (invalidated when transform changes)
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Collision detection — sweep-and-prune, zero per-frame allocation
  // ---------------------------------------------------------------------------

  /// Runs collision detection across all active colliders.
  /// Called by the tick pipeline each frame.
  static void runCollisionPass() {
    final n = _active.length;
    if (n < 2) return;

    // Insertion sort by worldBounds.left — O(n) for nearly-sorted data
    // (positions change only slightly frame-to-frame).
    for (int i = 1; i < n; i++) {
      final key = _active[i];
      final keyLeft = key.worldBounds.left;
      int j = i - 1;
      while (j >= 0 && _active[j].worldBounds.left > keyLeft) {
        _active[j + 1] = _active[j];
        j--;
      }
      _active[j + 1] = key;
    }

    // Sweep-and-prune on X axis.
    for (int i = 0; i < n; i++) {
      final a = _active[i];
      final aBounds = a.worldBounds;

      for (int j = i + 1; j < n; j++) {
        final b = _active[j];
        final bBounds = b.worldBounds;

        // Prune: b's left edge is past a's right edge → no more overlaps for a.
        if (bBounds.left > aBounds.right) break;

        // Layer filter
        if (a.layerMask & b.layerMask == 0) continue;

        // Y overlap check (X overlap guaranteed by sweep)
        if (aBounds.bottom <= bBounds.top || bBounds.bottom <= aBounds.top) {
          continue;
        }

        final intersection = aBounds.intersect(bBounds);
        if (!intersection.isEmpty) {
          a.broadcastEvent(CollisionEvent(a, b, intersection));
          b.broadcastEvent(CollisionEvent(b, a, intersection));
        }
      }
    }
  }
}

// -----------------------------------------------------------------------------
// OvalCollider
// -----------------------------------------------------------------------------

class OvalCollider extends Collider {
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

// -----------------------------------------------------------------------------
// BoxCollider
// -----------------------------------------------------------------------------

class BoxCollider extends Collider {
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

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Internal accessors
// -----------------------------------------------------------------------------

void internalUpdateScreenState(Collider collider,
    {required bool overlapping, required bool fullyInside}) {
  collider._wasOverlappingScreen = overlapping;
  collider._wasFullyInsideScreen = fullyInside;
}

bool internalGetWasOverlapping(Collider collider) =>
    collider._wasOverlappingScreen;
bool internalGetWasFullyInside(Collider collider) =>
    collider._wasFullyInsideScreen;
