# NDS Track Event Example

This example demonstrates how to use the NDS Track Event SDK in a Flutter application.

## Features Demonstrated

- Initialize the EventTracker
- Track simple events
- Track events with complex data structures
- Track multiple events at once
- Manual flush
- Monitor tracker health
- Set global user ID

## Running the Example

1. Navigate to the example directory:
```bash
cd example
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Code Examples

### Initialize Tracker

```dart
final tracker = EventTracker(
  apiKey: 'your-api-key',
  endpoint: 'https://api.example.com/v1/events/batch',
  flushIntervalMs: 5000,
  maxBatchSize: 20,
  maxQueueSize: 5000,
  offlineStorageEnabled: true,
  debug: true,
);
```

### Track Events

```dart
// Simple event
tracker.track('button_clicked', {
  'button_name': 'submit',
});

// Event with user ID
tracker.track('purchase', {
  'product_id': 'prod_123',
  'amount': 99.99,
}, userId: 'user_456');

// Complex event
tracker.track('custom_event', {
  'field_1': 'value',
  'nested': {
    'field_a': 'nested value',
    'field_b': [1, 2, 3],
  },
});
```

### Manual Flush

```dart
await tracker.flush();
```

### Check Health

```dart
final health = tracker.health();
print('Queue size: ${health.queueSize}');
print('Events sent: ${health.eventsSent}');
```

### Cleanup

```dart
await tracker.dispose();
```

