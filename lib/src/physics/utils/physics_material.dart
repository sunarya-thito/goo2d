class PhysicsMaterial {
  final double bounciness;
  final double friction;
  const PhysicsMaterial({
    this.bounciness = 0.0,
    this.friction = 0.4,
  });
  static const defaultMaterial = PhysicsMaterial();
}
