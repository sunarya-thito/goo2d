# Goo2D Performance Benchmarking Guide

This guide outlines the methodology for measuring and profiling the performance of the Goo2D engine. We use Flutter's official **Integration Performance Profiling** to ensure results reflect real-world usage on actual devices.

## 1. Overview

Goo2D performance is measured using the `integration_test` package. This allows us to capture:
- **Frame Build Times**: How long it takes to process `update()` and `render()`.
- **Mount Overhead**: The cost of adding thousands of objects to the scene.
- **Jank Metrics**: Missed frame budgets during intensive operations.

## 2. Infrastructure

### The Test File (`integration_test/performance_test.dart`)
We use `IntegrationTestWidgetsFlutterBinding.traceAction()` to wrap the code we want to profile.

```dart
final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

testWidgets('High Object Count Stress Test', (tester) async {
  await tester.pumpWidget(const GooGameApp());
  
  await binding.traceAction(() async {
    // Perform intensive game operations
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }, reportKey: 'stress_test');
});
```

### The Driver File (`test_driver/performance_test_driver.dart`)
The driver processes the performance data and writes it to a JSON file.

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

## 3. Key Metrics

When reviewing the generated `timeline_summary.json`, focus on:
- `average_frame_build_time_millis`: Goal is < 16ms (60fps) or < 8ms (120fps).
- `worst_frame_build_time_millis`: Identifies spikes (e.g., garbage collection or heavy initialization).
- `missed_frame_build_budget_count`: Total number of dropped frames.

## 4. Scaling & Stress Levels

Always test at multiple magnitudes to identify non-linear scaling ($O(N^2)$ or worse):
- **Normal**: 100 - 500 objects.
- **Stress**: 1,000 - 5,000 objects.
- **Extreme Stress**: 10,000+ objects.

## 5. Running Benchmarks

Benchmarks **MUST** be run in **Profile Mode** to get accurate results. Debug mode has significant overhead that invalidates performance data.

```bash
flutter drive \
  --driver=test_driver/performance_test_driver.dart \
  --target=integration_test/performance_test.dart \
  --profile
```

## 6. Pro-Tips

- **Warm-up**: Flutter's JIT and shader compilation can cause initial spikes. Use a warm-up period in your test before starting the `traceAction`.
- **Physical Devices**: Always prefer physical devices over emulators for final performance verification.
- **GPU Profiling**: For rendering bottlenecks, use the DevTools "Performance" tab alongside these integration tests.
