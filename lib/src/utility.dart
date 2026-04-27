import 'dart:math';
import 'dart:ui';

T lerp<T>(T a, T b, double t) {
  // convert a and b to dynamic, assuming they overload the operator
  return ((a as dynamic) + ((b as dynamic) - (a as dynamic)) * t) as T;
}

extension EnumListExtension<T extends Enum> on List<T> {
  List<T> betweenInclusive(T a, T b) {
    final indexMin = min(a.index, b.index);
    final indexMax = max(a.index, b.index);
    return sublist(indexMin, indexMax + 1);
  }

  List<T> betweenExclusive(T a, T b) {
    final indexMin = min(a.index, b.index);
    final indexMax = max(a.index, b.index);
    return sublist(indexMin + 1, indexMax);
  }

  List<T> between(T a, T b, {bool includeA = true, bool includeB = true}) {
    final indexMin = min(a.index, b.index);
    final indexMax = max(a.index, b.index);
    final start = includeA ? indexMin : indexMin + 1;
    final end = includeB ? indexMax + 1 : indexMax;
    return sublist(start, end);
  }
}

class SmoothDampResult<T> {
  final T value;
  final T velocity;
  const SmoothDampResult(this.value, this.velocity);
}

class MathUtils {
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
