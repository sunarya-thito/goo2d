import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// A set of parameters for filtering contact results. Define the angle by referring to their position in world space, where 0 degrees is parallel to the positive x-axis, 90 degrees is parallel to the positive y-axis, 180 degrees is parallel to the negative x-axis, and 270 degrees is parallel to the negative y-axis.
/// 
/// Equivalent to Unity's `ContactFilter2D`.
class ContactFilter {
  /// Returns a new contact filter with a state where it will not filter any contacts.
  static ContactFilter get noFilter => throw UnimplementedError('Implemented via Physics Worker');
  static set noFilter(ContactFilter value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A constant of the maximum normal angle used of 359.9999f.
  static double get normalAngleUpperLimit => throw UnimplementedError('Implemented via Physics Worker');
  static set normalAngleUpperLimit(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Given the current state of the contact filter, determine whether it would filter anything.
  bool get isFiltering => throw UnimplementedError('Implemented via Physics Worker');
  set isFiltering(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter the results to only include Collider2D with a Z coordinate (depth) greater than this value.
  double get minDepth => throw UnimplementedError('Implemented via Physics Worker');
  set minDepth(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter the results by the collision's normal angle using minNormalAngle and maxNormalAngle.
  bool get useNormalAngle => throw UnimplementedError('Implemented via Physics Worker');
  set useNormalAngle(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter the results to only include Collider2D with a Z coordinate (depth) less than this value.
  double get maxDepth => throw UnimplementedError('Implemented via Physics Worker');
  set maxDepth(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter within the minNormalAngle and maxNormalAngle range, or outside that range.
  bool get useOutsideNormalAngle => throw UnimplementedError('Implemented via Physics Worker');
  set useOutsideNormalAngle(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter the results to only include contacts with collision normal angles that are greater than this angle.
  double get minNormalAngle => throw UnimplementedError('Implemented via Physics Worker');
  set minNormalAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter results by layer mask.
  bool get useLayerMask => throw UnimplementedError('Implemented via Physics Worker');
  set useLayerMask(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter the results by depth using minDepth and maxDepth.
  bool get useDepth => throw UnimplementedError('Implemented via Physics Worker');
  set useDepth(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter within the minDepth and maxDepth range, or outside that range.
  bool get useOutsideDepth => throw UnimplementedError('Implemented via Physics Worker');
  set useOutsideDepth(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter the results to only include contacts with collision normal angles that are less than this angle.
  double get maxNormalAngle => throw UnimplementedError('Implemented via Physics Worker');
  set maxNormalAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets the contact filter to filter the results that only include Collider2D on the layers defined by the layer mask.
  int get layerMask => throw UnimplementedError('Implemented via Physics Worker');
  set layerMask(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Sets to filter contact results based on trigger collider involvement.
  bool get useTriggers => throw UnimplementedError('Implemented via Physics Worker');
  set useTriggers(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Turns off depth filtering by setting useDepth to false. The associated values of minDepth and maxDepth are not changed.
  void clearDepth() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Turns off normal angle filtering by setting useNormalAngle to false. The associated values of minNormalAngle and maxNormalAngle are not changed.
  void clearNormalAngle() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Sets the minDepth and maxDepth filter properties and turns on depth filtering by setting useDepth to true.
  /// - [minDepth]: The value used to set minDepth.
  /// - [maxDepth]: The value used to set maxDepth.
  void setDepth(double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks if the collider is a trigger and should be filtered by the useTriggers to be filtered.
  /// - [collider]: The Collider2D used to check for a trigger.
  bool isFilteringTrigger(Collider collider) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks if the GameObject.layer for obj is included in the layerMask to be filtered.
  /// - [obj]: The GameObject used to check the GameObject.layer.
  bool isFilteringLayerMask(GameObject obj) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks if the Transform for obj is within the depth range to be filtered.
  /// - [obj]: The GameObject used to check the z-position (depth) of Transform.position.
  bool isFilteringDepth(GameObject obj) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Sets the layerMask filter property using the layerMask parameter provided and also enables layer mask filtering by setting useLayerMask to true.
  /// - [layerMask]: The value used to set the layerMask.
  void setLayerMask(int layerMask) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Turns off layer mask filtering by setting useLayerMask to false. The associated value of layerMask is not changed.
  void clearLayerMask() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks if the angle of normal is within the normal angle range to be filtered.
  /// - [normal]: The normal used to calculate an angle.
  bool isFilteringNormalAngle(Vector2 normal) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Sets the minNormalAngle and maxNormalAngle filter properties and turns on normal angle filtering by setting useNormalAngle to true.
  /// - [minNormalAngle]: The value used to set the minNormalAngle.
  /// - [maxNormalAngle]: The value used to set the maxNormalAngle.
  void setNormalAngle(double minNormalAngle, double maxNormalAngle) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}