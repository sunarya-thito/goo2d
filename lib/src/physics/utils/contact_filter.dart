import 'package:goo2d/goo2d.dart';

/// A set of parameters for filtering contact results.
/// 
/// Equivalent to Unity's `ContactFilter2D`.
class ContactFilter {
  /// Layer mask to filter results by.
  int layerMask = ~0;
  
  /// Whether to use the layer mask.
  bool useLayerMask = false;
  
  /// Whether to filter results by trigger collider involvement.
  bool useTriggers = true;
  
  /// Whether to filter the results by depth.
  bool useDepth = false;
  
  /// Minimum depth to include.
  double minDepth = -double.infinity;
  
  /// Maximum depth to include.
  double maxDepth = double.infinity;

  /// Whether to filter results by normal angle.
  bool useNormalAngle = false;
  
  /// Minimum normal angle to include.
  double minNormalAngle = 0.0;
  
  /// Maximum normal angle to include.
  double maxNormalAngle = 360.0;

  /// Returns a new contact filter with a state where it will not filter any contacts.
  static ContactFilter get noFilter => ContactFilter()..useLayerMask = false;

  /// The upper limit for the normal angle.
  static const double normalAngleUpperLimit = 180.0;

  /// Whether to filter results by normal angle outside the range.
  bool useOutsideNormalAngle = false;

  /// Whether to filter results by depth outside the range.
  bool useOutsideDepth = false;

  /// Given the current state of the contact filter, determine whether it would filter anything.
  bool get isFiltering => useLayerMask || useDepth || useNormalAngle || !useTriggers;

  /// Sets the minDepth and maxDepth filter properties and turns on depth filtering.
  void setDepth(double minDepth, double maxDepth) {
    this.minDepth = minDepth;
    this.maxDepth = maxDepth;
    useDepth = true;
  }

  /// Clears the depth filter.
  void clearDepth() {
    useDepth = false;
    minDepth = -double.infinity;
    maxDepth = double.infinity;
  }

  /// Clears the normal angle filter.
  void clearNormalAngle() {
    useNormalAngle = false;
    minNormalAngle = 0.0;
    maxNormalAngle = 360.0;
  }

  /// Returns true if the filter is filtering by trigger.
  bool isFilteringTrigger() => !useTriggers;

  /// Returns true if the filter is filtering by layer mask.
  bool isFilteringLayerMask() => useLayerMask;

  /// Returns true if the filter is filtering by depth.
  bool isFilteringDepth() => useDepth;

  /// Clears the layer mask filter.
  void clearLayerMask() {
    useLayerMask = false;
    layerMask = ~0;
  }

  /// Returns true if the filter is filtering by normal angle.
  bool isFilteringNormalAngle() => useNormalAngle;

  /// Sets the layerMask filter property and enables layer mask filtering.
  void setLayerMask(int layerMask) {
    this.layerMask = layerMask;
    useLayerMask = true;
  }

  /// Sets the normal angle range and enables normal angle filtering.
  void setNormalAngle(double minNormalAngle, double maxNormalAngle) {
    this.minNormalAngle = minNormalAngle;
    this.maxNormalAngle = maxNormalAngle;
    useNormalAngle = true;
  }
}