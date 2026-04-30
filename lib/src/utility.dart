import 'dart:math';
import 'dart:ui';

/// Performs a linear interpolation between two values of type [T].
///
/// This function assumes that the type [T] supports addition, subtraction, 
/// and multiplication by a [double]. It is used for smooth transitions between 
/// numerical states or colors.
///
/// ```dart
/// final value = lerp(0.0, 10.0, 0.5); // Returns 5.0
/// ```
///
/// * [a]: The starting value.
/// * [b]: The ending value.
/// * [t]: The interpolation factor, typically between 0.0 and 1.0.
T lerp<T>(T a, T b, double t) {
  // convert a and b to dynamic, assuming they overload the operator
  return ((a as dynamic) + ((b as dynamic) - (a as dynamic)) * t) as T;
}

/// Provides utility methods for slicing a [List] of enums based on their indices.
///
/// This extension simplifies the process of getting a subset of enums within
/// a range, which is useful for systems that use enums to represent layers 
/// or sequential states.
extension EnumListExtension<T extends Enum> on List<T> {
  /// Returns a sublist of enums between [a] and [b], including both ends.
  ///
  /// The order of [a] and [b] does not matter; the method internally determines
  /// the minimum and maximum indices to ensure a valid range.
  ///
  /// * [a]: The first boundary enum.
  /// * [b]: The second boundary enum.
  List<T> betweenInclusive(T a, T b) {
    final indexMin = min(a.index, b.index);
    final indexMax = max(a.index, b.index);
    return sublist(indexMin, indexMax + 1);
  }

  /// Returns a sublist of enums between [a] and [b], excluding both ends.
  ///
  /// This is useful when you need the items strictly contained within a range 
  /// without the boundary values themselves.
  ///
  /// * [a]: The first boundary enum.
  /// * [b]: The second boundary enum.
  List<T> betweenExclusive(T a, T b) {
    final indexMin = min(a.index, b.index);
    final indexMax = max(a.index, b.index);
    return sublist(indexMin + 1, indexMax);
  }

  /// Returns a sublist of enums between [a] and [b] with optional inclusion.
  ///
  /// This method provides the most flexibility for range selection, allowing 
  /// you to specify exactly which boundaries should be part of the result.
  ///
  /// * [a]: The first boundary enum.
  /// * [b]: The second boundary enum.
  /// * [includeA]: Whether to include the enum with the lower index.
  /// * [includeB]: Whether to include the enum with the higher index.
  List<T> between(T a, T b, {bool includeA = true, bool includeB = true}) {
    final indexMin = min(a.index, b.index);
    final indexMax = max(a.index, b.index);
    final start = includeA ? indexMin : indexMin + 1;
    final end = includeB ? indexMax + 1 : indexMax;
    return sublist(start, end);
  }
}

/// Represents the output of a smooth damping calculation.
///
/// This container holds both the updated value and the resulting velocity,
/// allowing for continuous smoothing across multiple frames. It is used 
/// by [MathUtils.smoothDamp] and related functions to maintain 
/// physics-based continuity.
///
/// ```dart
/// final result = MathUtils.smoothDamp(current, target, velocity, time, dt);
/// current = result.value;
/// velocity = result.velocity;
/// ```
/// 
/// See also:
/// * [MathUtils] for the algorithms that produce these results.
class SmoothDampResult<T> {
  /// The interpolated value for the current frame.
  /// 
  /// Represents the new state of the object.
  final T value;

  /// The velocity calculated during the damping process.
  /// 
  /// Should be passed back into the next damping call for continuity.
  final T velocity;

  /// Creates a new [SmoothDampResult] with the given [value] and [velocity].
  /// 
  /// This constructor is used by the damping utility functions to return 
  /// the calculated state for the next frame.
  /// 
  /// * [value]: The calculated value for the current frame.
  /// * [velocity]: The calculated velocity for the next frame.
  const SmoothDampResult(this.value, this.velocity);
}

/// A collection of static mathematical utility functions for game development.
///
/// This class provides optimized algorithms for common tasks like smooth
/// interpolation and vector math that are frequently used in camera systems
/// and physics calculations.
/// 
/// ```dart
/// final res = MathUtils.smoothDamp(0, 10, 0, 0.5, 0.016);
/// ```
/// 
/// See also:
/// * [SmoothDampResult] for the data structure returned by these methods.
class MathUtils {
  /// Gradually changes a value towards a desired goal over time.
  ///
  /// This is similar to Unity's SmoothDamp. It uses a spring-damper model
  /// to provide a smooth, natural-looking transition that never overshoots 
  /// the target value.
  ///
  /// * [current]: The current position.
  /// * [target]: The position we are trying to reach.
  /// * [currentVelocity]: The current velocity.
  /// * [smoothTime]: Approximately the time it will take to reach the target.
  /// * [dt]: The time elapsed since the last call (delta time).
  /// * [maxSpeed]: Optionally limits the maximum speed.
  static SmoothDampResult<double> smoothDamp(
    double current,
    double target,
    double currentVelocity,
    double smoothTime,
    double dt, [
    double maxSpeed = double.infinity,
  ]) {
    smoothTime = max(0.0001, smoothTime);
    final omega = 2.0 / smoothTime;
    final x = omega * dt;
    final exp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x);

    double change = current - target;
    final maxChange = maxSpeed * smoothTime;
    change = change.clamp(-maxChange, maxChange);

    final temp = (currentVelocity + omega * change) * dt;
    final newVelocity = (currentVelocity - omega * temp) * exp;
    double newValue = target + (change + temp) * exp;

    // Prevent overshooting
    if ((target - current > 0) == (newValue > target)) {
      newValue = target;
      return SmoothDampResult(newValue, 0);
    }

    return SmoothDampResult(newValue, newVelocity);
  }

  /// Gradually changes an [Offset] towards a desired goal over time.
  ///
  /// This is the 2D vector version of [smoothDamp]. It is ideal for smooth
  /// camera following or UI element transitions.
  ///
  /// * [current]: The current position vector.
  /// * [target]: The target position vector.
  /// * [currentVelocity]: The current velocity vector.
  /// * [smoothTime]: Approximately the time it will take to reach the target.
  /// * [dt]: The delta time.
  /// * [maxSpeed]: Optionally limits the maximum speed of the vector change.
  static SmoothDampResult<Offset> smoothDampOffset(
    Offset current,
    Offset target,
    Offset currentVelocity,
    double smoothTime,
    double dt, [
    double maxSpeed = double.infinity,
  ]) {
    smoothTime = max(0.0001, smoothTime);
    final omega = 2.0 / smoothTime;
    final x = omega * dt;
    final exp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x);

    Offset change = current - target;
    final maxChange = maxSpeed * smoothTime;
    if (change.distance > maxChange) {
      change = change / change.distance * maxChange;
    }

    final temp = (currentVelocity + change * omega) * dt;
    final newVelocity = (currentVelocity - change * (omega * omega * dt)) * exp;
    final newValue = target + (change + temp) * exp;

    return SmoothDampResult(newValue, newVelocity);
  }
}
