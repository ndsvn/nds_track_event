import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/event.dart';

/// Thread-safe FIFO queue for events
class EventQueue {

  EventQueue({
    required int maxSize,
    this.onEventDropped,
    this.onEventAdded,
  }) : _maxSize = maxSize;
  final int _maxSize;
  final Queue<Event> _queue = Queue<Event>();
  final ValueNotifier<int> _sizeNotifier = ValueNotifier<int>(0);

  /// Callback when queue is full and event is dropped
  final void Function(Event droppedEvent)? onEventDropped;

  /// Callback when event is added to queue
  final void Function(Event event)? onEventAdded;

  /// Add event to the queue
  /// Returns true if added, false if queue is full and event was dropped
  bool enqueue(Event event) {
    if (_queue.length >= _maxSize) {
      onEventDropped?.call(event);
      return false;
    }

    _queue.add(event);
    _sizeNotifier.value = _queue.length;
    onEventAdded?.call(event);
    return true;
  }

  /// Add multiple events to the queue
  /// Returns the number of events successfully added
  int enqueueAll(List<Event> events) {
    int addedCount = 0;

    for (final event in events) {
      if (_queue.length >= _maxSize) {
        onEventDropped?.call(event);
        continue;
      }

      _queue.add(event);
      addedCount++;
      onEventAdded?.call(event);
    }

    _sizeNotifier.value = _queue.length;
    return addedCount;
  }

  /// Remove and return the first event from the queue
  /// Returns null if queue is empty
  Event? dequeue() {
    if (_queue.isEmpty) {
      return null;
    }

    final event = _queue.removeFirst();
    _sizeNotifier.value = _queue.length;
    return event;
  }

  /// Remove and return up to [count] events from the queue
  /// Returns a list of events (may be less than count if queue doesn't have enough)
  List<Event> dequeueBatch(int count) {
    if (_queue.isEmpty || count <= 0) {
      return [];
    }

    final batchSize = count < _queue.length ? count : _queue.length;
    final batch = <Event>[];

    for (int i = 0; i < batchSize; i++) {
      batch.add(_queue.removeFirst());
    }

    _sizeNotifier.value = _queue.length;
    return batch;
  }

  /// Peek at the first event without removing it
  /// Returns null if queue is empty
  Event? peek() {
    if (_queue.isEmpty) {
      return null;
    }
    return _queue.first;
  }

  /// Peek at up to [count] events without removing them
  List<Event> peekBatch(int count) {
    if (_queue.isEmpty || count <= 0) {
      return [];
    }

    final batchSize = count < _queue.length ? count : _queue.length;
    return _queue.take(batchSize).toList();
  }

  /// Add event back to the front of the queue (for failed sends)
  /// Returns true if added, false if queue is full
  bool requeueToFront(Event event) {
    if (_queue.length >= _maxSize) {
      onEventDropped?.call(event);
      return false;
    }

    _queue.addFirst(event);
    _sizeNotifier.value = _queue.length;
    return true;
  }

  /// Add multiple events back to the front of the queue (for failed sends)
  /// Events are added in the same order they are provided
  /// Returns the number of events successfully requeued
  int requeueAllToFront(List<Event> events) {
    int requeuedCount = 0;

    // Add in reverse order so they end up in the correct order at the front
    for (int i = events.length - 1; i >= 0; i--) {
      final event = events[i];

      if (_queue.length >= _maxSize) {
        onEventDropped?.call(event);
        continue;
      }

      _queue.addFirst(event);
      requeuedCount++;
    }

    _sizeNotifier.value = _queue.length;
    return requeuedCount;
  }

  /// Get current queue size
  int get size => _queue.length;

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Check if queue is full
  bool get isFull => _queue.length >= _maxSize;

  /// Get maximum queue size
  int get maxSize => _maxSize;

  /// Get remaining capacity
  int get remainingCapacity => _maxSize - _queue.length;

  /// Get size notifier for reactive updates
  ValueListenable<int> get sizeNotifier => _sizeNotifier;

  /// Clear all events from the queue
  void clear() {
    _queue.clear();
    _sizeNotifier.value = 0;
  }

  /// Get a copy of all events in the queue (for debugging)
  List<Event> toList() {
    return List<Event>.from(_queue);
  }

  /// Dispose resources
  void dispose() {
    _queue.clear();
    _sizeNotifier.dispose();
  }

  @override
  String toString() {
    return 'EventQueue{size: ${_queue.length}, maxSize: $_maxSize, isEmpty: $isEmpty, isFull: $isFull}';
  }
}

