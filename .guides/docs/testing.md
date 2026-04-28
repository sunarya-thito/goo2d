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
- **Value**: Avoid "obvious" tests. Focus on logic, complex state, and side effects rather than simple property assignments.

## 3. Environment & Isolation
- **Binding**: Use `AutomatedTestWidgetsFlutterBinding.ensureInitialized()`.
- **Mocks**: Mock `GameAsset` and `GameTicker` for unit tests. 
- **Time**: Prefer `FakeAsync` for ticker/coroutine tests.
- **Teardown**: Always dispose created GameObjects/Components in `tearDown()`.

## 4. Benchmarking
Benchmarks must follow the standards outlined in the [Benchmarking Guide](file:///e:/gameproj/goo2d/.guides/docs/benchmarking.md). 

Key Requirements:
- Use `package:benchmark_harness`.
- Files must reside in `test/benchmarks/`.
- Must inherit from `BenchmarkBase`.

## 5. UI Testing
- Use `testWidgets`.
- Verify `GameRenderObject` state directly for high-precision layout/paint checks.
- Use `tester.pump(duration)` to simulate engine frames.
