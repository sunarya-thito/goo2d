import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// A set of options that control how physics operates when using the job system to multithread the physics simulation.
/// 
/// Equivalent to Unity's `PhysicsJobOptions2D`.
class PhysicsJobOptions {
  /// Controls the minimum number of bodies to be cleared in each simulation job.
  int get clearBodyForcesPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set clearBodyForcesPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of Rigidbody2D being interpolated in each simulation job.
  int get interpolationPosesPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set interpolationPosesPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of contacts to collide in each simulation job.
  int get collideContactsPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set collideContactsPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Scales the cost of each body during discrete island solving.
  int get islandSolverBodyCostScale => throw UnimplementedError('Implemented via Physics Worker');
  set islandSolverBodyCostScale(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of flags to be cleared in each simulation job.
  int get clearFlagsPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set clearFlagsPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The minimum threshold cost of all bodies, contacts and joints in an island during discrete island solving.
  int get islandSolverCostThreshold => throw UnimplementedError('Implemented via Physics Worker');
  set islandSolverCostThreshold(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Scales the cost of each joint during discrete island solving.
  int get islandSolverJointCostScale => throw UnimplementedError('Implemented via Physics Worker');
  set islandSolverJointCostScale(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of trigger contacts to update in each simulation job.
  int get updateTriggerContactsPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set updateTriggerContactsPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Scales the cost of each contact during discrete island solving.
  int get islandSolverContactCostScale => throw UnimplementedError('Implemented via Physics Worker');
  set islandSolverContactCostScale(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of fixtures to synchronize in the broadphase during continuous island solving in each simulation job.
  int get syncContinuousFixturesPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set syncContinuousFixturesPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of fixtures to synchronize in the broadphase during discrete island solving in each simulation job.
  int get syncDiscreteFixturesPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set syncDiscreteFixturesPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of nearest contacts to find in each simulation job.
  int get findNearestContactsPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set findNearestContactsPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of contacts to solve in each simulation job when performing island solving.
  int get islandSolverContactsPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set islandSolverContactsPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of bodies to solve in each simulation job when performing island solving.
  int get islandSolverBodiesPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set islandSolverBodiesPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum number of new contacts to find in each simulation job.
  int get newContactsPerJob => throw UnimplementedError('Implemented via Physics Worker');
  set newContactsPerJob(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should physics simulation sort multi-threaded results to maintain processing order consistency?
  bool get useConsistencySorting => throw UnimplementedError('Implemented via Physics Worker');
  set useConsistencySorting(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should physics simulation use multithreading?
  bool get useMultithreading => throw UnimplementedError('Implemented via Physics Worker');
  set useMultithreading(bool value) => throw UnimplementedError('Implemented via Physics Worker');

}