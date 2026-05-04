import 'package:goo2d/src/physics/worker/engine/collision/narrowphase.dart';

/// Tracks collision/trigger state transitions between frames.
///
/// Each frame, the [update] method is called with the current contacts.
/// It returns enter/stay/exit events by comparing with the previous frame.
class ContactTracker {
  final Set<(int, int)> _previousContacts = {};
  final Set<(int, int)> _previousTriggers = {};

  /// Results from the last update.
  final List<ContactEvent> enterEvents = [];
  final List<ContactEvent> stayEvents = [];
  final List<ContactEvent> exitEvents = [];
  final List<TriggerEvent> triggerEnterEvents = [];
  final List<TriggerEvent> triggerStayEvents = [];
  final List<TriggerEvent> triggerExitEvents = [];

  /// Updates the tracker with the current frame's contacts.
  ///
  /// [contacts] are the resolved narrowphase contacts this frame.
  /// [isTrigger] is a function that returns true if a collider is a trigger.
  void update(List<NarrowphaseContact> contacts,
      bool Function(int colliderHandle) isTrigger) {
    enterEvents.clear();
    stayEvents.clear();
    exitEvents.clear();
    triggerEnterEvents.clear();
    triggerStayEvents.clear();
    triggerExitEvents.clear();

    final currentContacts = <(int, int)>{};
    final currentTriggers = <(int, int)>{};

    for (final c in contacts) {
      final pair = _normalize(c.colliderA, c.colliderB);
      final isATrigger = isTrigger(c.colliderA);
      final isBTrigger = isTrigger(c.colliderB);

      if (isATrigger || isBTrigger) {
        // Trigger pair
        currentTriggers.add(pair);
        if (_previousTriggers.contains(pair)) {
          triggerStayEvents.add(TriggerEvent(c.colliderA, c.colliderB));
        } else {
          triggerEnterEvents.add(TriggerEvent(c.colliderA, c.colliderB));
        }
      } else {
        // Collision pair
        currentContacts.add(pair);
        if (_previousContacts.contains(pair)) {
          stayEvents.add(ContactEvent(
            colliderA: c.colliderA,
            colliderB: c.colliderB,
            bodyA: c.bodyA,
            bodyB: c.bodyB,
            normal: c.manifold.normal,
          ));
        } else {
          enterEvents.add(ContactEvent(
            colliderA: c.colliderA,
            colliderB: c.colliderB,
            bodyA: c.bodyA,
            bodyB: c.bodyB,
            normal: c.manifold.normal,
          ));
        }
      }
    }

    // Exit events: were in previous, not in current
    for (final pair in _previousContacts) {
      if (!currentContacts.contains(pair)) {
        exitEvents.add(ContactEvent(
          colliderA: pair.$1,
          colliderB: pair.$2,
          bodyA: -1,
          bodyB: -1,
        ));
      }
    }
    for (final pair in _previousTriggers) {
      if (!currentTriggers.contains(pair)) {
        triggerExitEvents.add(TriggerEvent(pair.$1, pair.$2));
      }
    }

    // Swap
    _previousContacts
      ..clear()
      ..addAll(currentContacts);
    _previousTriggers
      ..clear()
      ..addAll(currentTriggers);
  }

  (int, int) _normalize(int a, int b) => a < b ? (a, b) : (b, a);
}

/// A collision contact event (enter, stay, or exit).
class ContactEvent {
  final int colliderA;
  final int colliderB;
  final int bodyA;
  final int bodyB;
  final dynamic normal; // Vector2 or null for exit

  const ContactEvent({
    required this.colliderA,
    required this.colliderB,
    required this.bodyA,
    required this.bodyB,
    this.normal,
  });
}

/// A trigger event (enter, stay, or exit).
class TriggerEvent {
  final int colliderA;
  final int colliderB;

  const TriggerEvent(this.colliderA, this.colliderB);
}
