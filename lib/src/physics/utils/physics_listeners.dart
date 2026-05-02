import 'package:goo2d/goo2d.dart';

mixin CollisionListener implements EventListener {
  void onCollisionEnter(Collision collision) {}
  void onCollisionStay(Collision collision) {}
  void onCollisionExit(Collision collision) {}
}
mixin TriggerListener implements EventListener {
  void onTriggerEnter(Collider other) {}
  void onTriggerStay(Collider other) {}
  void onTriggerExit(Collider other) {}
}
