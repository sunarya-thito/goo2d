import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Represents a group of PhysicsShape2D and their geometry.
///
/// Equivalent to Unity's `PhysicsShapeGroup2D`.
class PhysicsShapeGroup {
  final List<PhysicsShape> _shapes = [];
  final List<Vector2> _vertices = [];
  Matrix4 localToWorldMatrix = Matrix4.identity();

  int get shapeCount => _shapes.length;
  int get vertexCount => _vertices.length;

  void deleteShape(int shapeIndex) => _shapes.removeAt(shapeIndex);

  int addCapsule(Vector2 vertex0, Vector2 vertex1, double radius) {
    final idx = _vertices.length;
    _vertices.add(vertex0.clone());
    _vertices.add(vertex1.clone());
    _shapes.add(PhysicsShape(shapeType: PhysicsShapeType.capsule, radius: radius, vertexStartIndex: idx, vertexCount: 2));
    return _shapes.length - 1;
  }

  int addPolygon(List<Vector2> vertices) {
    final idx = _vertices.length;
    _vertices.addAll(vertices.map((v) => v.clone()));
    _shapes.add(PhysicsShape(shapeType: PhysicsShapeType.polygon, vertexStartIndex: idx, vertexCount: vertices.length));
    return _shapes.length - 1;
  }

  void add(PhysicsShapeGroup physicsShapeGroup) {
    final offset = _vertices.length;
    _vertices.addAll(physicsShapeGroup._vertices.map((v) => v.clone()));
    for (final shape in physicsShapeGroup._shapes) {
      _shapes.add(PhysicsShape(
        shapeType: shape.shapeType, radius: shape.radius,
        vertexStartIndex: shape.vertexStartIndex + offset, vertexCount: shape.vertexCount,
        useAdjacentStart: shape.useAdjacentStart, useAdjacentEnd: shape.useAdjacentEnd,
      ));
    }
  }

  int addEdges(List<Vector2> vertices, double edgeRadius) {
    final idx = _vertices.length;
    _vertices.addAll(vertices.map((v) => v.clone()));
    _shapes.add(PhysicsShape(shapeType: PhysicsShapeType.edges, radius: edgeRadius, vertexStartIndex: idx, vertexCount: vertices.length));
    return _shapes.length - 1;
  }

  PhysicsShape getShape(int shapeIndex) => _shapes[shapeIndex];

  void getShapeData(List<PhysicsShape> shapes, List<Vector2> vertices) {
    shapes.clear(); shapes.addAll(_shapes);
    vertices.clear(); vertices.addAll(_vertices);
  }

  void clear() { _shapes.clear(); _vertices.clear(); }

  int addCircle(Vector2 center, double radius) {
    final idx = _vertices.length;
    _vertices.add(center.clone());
    _shapes.add(PhysicsShape(shapeType: PhysicsShapeType.circle, radius: radius, vertexStartIndex: idx, vertexCount: 1));
    return _shapes.length - 1;
  }

  int addBox(Vector2 center, Vector2 size, double angle, double edgeRadius) {
    final hw = size.x / 2; final hh = size.y / 2;
    final idx = _vertices.length;
    _vertices.addAll([
      Vector2(center.x - hw, center.y - hh), Vector2(center.x + hw, center.y - hh),
      Vector2(center.x + hw, center.y + hh), Vector2(center.x - hw, center.y + hh),
    ]);
    _shapes.add(PhysicsShape(shapeType: PhysicsShapeType.polygon, radius: edgeRadius, vertexStartIndex: idx, vertexCount: 4));
    return _shapes.length - 1;
  }

  Vector2 getShapeVertex(int shapeIndex, int vertexIndex) {
    final shape = _shapes[shapeIndex];
    return _vertices[shape.vertexStartIndex + vertexIndex];
  }

  void getShapeVertices(int shapeIndex, List<Vector2> vertices) {
    final shape = _shapes[shapeIndex];
    vertices.clear();
    for (var i = 0; i < shape.vertexCount; i++) {
      vertices.add(_vertices[shape.vertexStartIndex + i]);
    }
  }

  void setShapeAdjacentVertices(int shapeIndex, bool useAdjacentStart, bool useAdjacentEnd, Vector2 adjacentStart, Vector2 adjacentEnd) {
    final shape = _shapes[shapeIndex];
    shape.useAdjacentStart = useAdjacentStart;
    shape.useAdjacentEnd = useAdjacentEnd;
    shape.adjacentStart.setFrom(adjacentStart);
    shape.adjacentEnd.setFrom(adjacentEnd);
  }

  void setShapeVertex(int shapeIndex, int vertexIndex, Vector2 vertex) {
    final shape = _shapes[shapeIndex];
    _vertices[shape.vertexStartIndex + vertexIndex] = vertex.clone();
  }

  void setShapeRadius(int shapeIndex, double radius) => _shapes[shapeIndex].radius = radius;
}
