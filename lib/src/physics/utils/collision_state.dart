/// The lifecycle state of a collision or trigger overlap.
/// 
/// Used to distinguish between the initial impact, sustained contact, 
/// and the final separation of two colliders.
enum CollisionState { 
  /// The first frame where overlap is detected.
  enter, 
  
  /// Subsequent frames where overlap continues.
  stay, 
  
  /// The frame where objects stop overlapping.
  exit 
}
