# AI Agent Testing & Benchmarking Rules

## 1. Test File Organization
- **Location**: `test/src/` MUST mirror `lib/src/`.
- **Naming**: `[filename]_test.dart`.
- **Granularity**: 1 test file per 1 source file. No "god-files".

## 2. Test Internal Structure
- **Root Group**: `group('[ClassName]', () { ... })` for each class in the file.
- **Method Group**: `group('[methodName]()', () { ... })` for public methods.
- **Atomicity**: Each `test()` must verify ONE behavior. Use descriptive strings: `'should [behavior] when [context]'`.
- **Pattern**: Arrange -> Act -> Assert.

## 3. Environment & Isolation
- **Binding**: Use `AutomatedTestWidgetsFlutterBinding.ensureInitialized()`.
- **Mocks**: Mock `GameAsset` and `GameTicker` for unit tests. 
- **Time**: Prefer `FakeAsync` for ticker/coroutine tests.
- **Teardown**: Always dispose created GameObjects/Components in `tearDown()`.

## 4. Benchmarking with benchmark_harness
Benchmarks must use `package:benchmark_harness` for consistent results.
- **Base Class**: Inherit from `BenchmarkBase`.
- **Hooks**: Use `setup()` for one-time initialization and `run()` for the code under test.
- **Execution**: Run benchmarks in isolation (not within `testWidgets` unless testing rendering overhead).

```dart
import 'package:benchmark_harness/benchmark_harness.dart';

class MyBenchmark extends BenchmarkBase {
  MyBenchmark() : super('FeatureName');

  @override
  void setup() { /* Prepare data */ }

  @override
  void run() { /* Code to measure */ }
}

void main() {
  MyBenchmark().report();
}
```

## 5. UI Testing
- Use `testWidgets`.
- Verify `GameRenderObject` state directly for high-precision layout/paint checks.
- Use `tester.pump(duration)` to simulate engine frames.
