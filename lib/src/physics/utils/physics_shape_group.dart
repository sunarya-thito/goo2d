import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Represents a group of PhysicsShape2D and their geometry.
/// 
/// Equivalent to Unity's `PhysicsShapeGroup2D`.
class PhysicsShapeGroup {
  /// Gets or sets a matrix that transforms the PhysicsShapeGroup2D vertices from local space into world space.
  Matrix4 get localToWorldMatrix => throw UnimplementedError('Implemented via Physics Worker');
  set localToWorldMatrix(Matrix4 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The total number of PhysicsShape2D in the shape group. (Read Only)
  int get shapeCount => throw UnimplementedError('Implemented via Physics Worker');
  set shapeCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The total number of vertices in the shape group used to represent all PhysicsShape2D within it. (Read Only)
  int get vertexCount => throw UnimplementedError('Implemented via Physics Worker');
  set vertexCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// When destroying a shape at the specified shapeIndex, all other shapes that exist above the specified shapeIndex will have their shape indices updated appropriately.
  /// - [shapeIndex]: The index of the shape stored the PhysicsShapeGroup2D.
  void deleteShape(int shapeIndex) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a capsule shape (PhysicsShapeType2D.Capsule) to the shape group.
  /// - [vertex0]: The position of one end of a capsule shape. This point represents the center point of a logical circle at the end of a capsule.
  /// - [vertex1]: The position of the opposite end of a capsule shape. This point represents the center point of a logical circle at the opposite end of a capsule.
  /// - [radius]: The radius of the capsule defining a radius around the vertex0 and vertex1 and the area between them.
  int addCapsule(Vector2 vertex0, Vector2 vertex1, double radius) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a polygon shape (PhysicsShapeType2D.Polygon) to the shape group.
  /// - [vertices]: A list of vertices that represent a continuous set of edges of a convex polygon with each vertex connecting to the following vertex to form each edge. The final vertex implicitly connects to the first vertex. The maximum allowed list length is defined by Physics2D.MaxPolygonShapeVertices.
  int addPolygon(List<Vector2> vertices) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a copy of all the PhysicsShape2D and their geometry from the specified physicsShapeGroup into this shape group. The specified physicsShapeGroup is not modified.
  /// - [physicsShapeGroup]: The PhysicsShapeGroup2D to add to this shape group. (Read Only)
  void add(PhysicsShapeGroup physicsShapeGroup) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds an edges shape (PhysicsShapeType2D.Edges) to the shape group.
  /// - [vertices]: A list of vertices that represent a continuous set of edges with each vertex connecting to the following vertex to form each edge.
  /// - [edgeRadius]: The radius extending around each edge. This is identical to EdgeCollider2D.edgeRadius.
  int addEdges(List<Vector2> vertices, double edgeRadius) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets the PhysicsShape2D stored at the specified shapeIndex.
  /// - [shapeIndex]: The index of the shape stored the PhysicsShapeGroup2D. The shape index is zero-based with the shape group having a quantity of shapes specified by shapeCount.
  PhysicsShape getShape(int shapeIndex) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets a copy of both the shapes and vertices in the PhysicsShapeGroup2D.
  /// - [shapes]: A list that will be populated with a copy of all the shapes in the PhysicsShapeGroup2D.
  /// - [vertices]: A list that will be populated with a copy of all the vertices in the PhysicsShapeGroup2D.
  void getShapeData(List<PhysicsShape> shapes, List<Vector2> vertices) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Clears all the vertices and shapes from the PhysicsShapeGroup.
  void clear() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a circle shape (PhysicsShapeType2D.Circle) to the shape group.
  /// - [center]: The center point of the circle shape. This is analogous to Collider2D.offset.
  /// - [radius]: The radius of the circle defining a radius around the center. This is identical to CircleCollider2D.radius.
  int addCircle(Vector2 center, double radius) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a box shape (PhysicsShapeType2D.Polygon) to the shape group.
  /// - [center]: The center point of the box shape. This is analogous to Collider2D.offset.
  /// - [size]: The size of the box. This is identical to BoxCollider2D.size.
  /// - [angle]: The angle in degrees the box should be rotated around the center.
  /// - [edgeRadius]: The radius extending around the edges of the box. This is identical to BoxCollider2D.edgeRadius.
  int addBox(Vector2 center, Vector2 size, double angle, double edgeRadius) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets a single vertex of a shape. The vertex index is zero-based with the shape having a quantity of vertex specified by PhysicsShape2D.vertexCount.
  /// - [shapeIndex]: The index of the shape stored in the PhysicsShapeGroup2D. The shape index is zero-based with the shape group having a quantity of shapes specified by shapeCount.
  /// - [vertexIndex]: The index of the shape vertex stored in the PhysicsShapeGroup2D. The vertex index is zero-based with the shape having a quantity of vertex specified by PhysicsShape2D.vertexCount.
  Vector2 getShapeVertex(int shapeIndex, int vertexIndex) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets a copy of the shape vertices in the PhysicsShapeGroup2D.
  /// - [shapeIndex]: The index of the shape stored in the PhysicsShapeGroup2D. The shape index is zero-based with the shape group having a quantity of shapes specified by shapeCount.
  /// - [vertices]: A list that will be populated with a copy of all the shape vertices in the PhysicsShapeGroup2D.
  void getShapeVertices(int shapeIndex, List<Vector2> vertices) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Sets the adjacent vertices of a shape.
  /// - [shapeIndex]: The index of the shape to be modified that is stored the PhysicsShapeGroup2D.
  /// - [useAdjacentStart]: Sets the PhysicsShape2D.useAdjacentStart property of the selected shape.
  /// - [useAdjacentEnd]: Sets the PhysicsShape2D.useAdjacentEnd property of the selected shape.
  /// - [adjacentStart]: Sets the PhysicsShape2D.adjacentStart property of the selected shape.
  /// - [adjacentEnd]: Sets the PhysicsShape2D.adjacentEnd property of the selected shape.
  void setShapeAdjacentVertices(int shapeIndex, bool useAdjacentStart, bool useAdjacentEnd, Vector2 adjacentStart, Vector2 adjacentEnd) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Sets a single vertex of a shape.
  /// - [shapeIndex]: The index of the shape stored in the PhysicsShapeGroup2D. The shape index is zero-based with the shape group having a quantity of shapes specified by shapeCount.
  /// - [vertexIndex]: The index of the shape vertex stored in the PhysicsShapeGroup2D. The vertex index is zero-based with the shape having a quantity of vertex specified by PhysicsShape2D.vertexCount.
  /// - [vertex]: The value to set the shape vertex to.
  void setShapeVertex(int shapeIndex, int vertexIndex, Vector2 vertex) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Sets the radius of a shape.
  /// - [shapeIndex]: The index of the shape stored in the PhysicsShapeGroup2D. The shape index is zero-based with the shape group having a quantity of shapes specified by shapeCount.
  /// - [radius]: The value to set the shape radius to.
  void setShapeRadius(int shapeIndex, double radius) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}