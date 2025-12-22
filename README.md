# NDS Track Event SDK

A robust Flutter SDK for event tracking with offline support, automatic retry logic, and batch sending capabilities.

## Features

- ✅ **Local Event Queue**: Events stored in SQLite for reliability
- ✅ **Batch Sending**: Automatically batches events for efficient network usage
- ✅ **Retry Logic**: Exponential backoff retry mechanism
- ✅ **Offline Support**: Events saved locally when offline, synced when back online
- ✅ **Non-blocking**: All operations run in background, won't block UI
- ✅ **Thread-safe**: Safe to use from multiple isolates
- ✅ **Lifecycle Aware**: Automatically handles app background/foreground

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  nds_track_event: ^1.0.0
```

## Quick Start

### 1. Initialize the SDK

```dart
import 'package:nds_track_event/nds_track_event.dart';

final tracker = EventTracker(
  apiKey: "YOUR_API_KEY",
  endpoint: "https://api.yoursaas.com/v1/events/batch",
  flushIntervalMs: 5000,  // Auto-flush every 5 seconds
  maxBatchSize: 20,       // Send 20 events per batch
  maxQueueSize: 5000,     // Maximum queue size
  offlineStorageEnabled: true,
  debug: false,
);
```

### 2. Track Events

```dart
// Simple event
tracker.track("button_clicked", {"button": "submit"});

// Event with user ID
tracker.track("purchase", {
  "product_id": "prod_123",
  "amount": 99.99,
  "currency": "USD"
}, userId: "user_456");
```

### 3. Set Global User ID

```dart
tracker.setUserId("user_123");
```

### 4. Manual Flush

```dart
// Force send all pending events
await tracker.flush();
```

### 5. Cleanup

```dart
// When done (e.g., app closing)
await tracker.dispose();
```

## Configuration Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `apiKey` | String | **required** | Your API key for authentication |
| `endpoint` | String | **required** | The batch ingestion endpoint URL |
| `flushIntervalMs` | int | 5000 | Auto-flush interval in milliseconds |
| `maxBatchSize` | int | 20 | Maximum events per batch |
| `maxQueueSize` | int | 5000 | Maximum in-memory queue size |
| `offlineStorageEnabled` | bool | true | Enable SQLite offline storage |
| `debug` | bool | false | Enable debug logging |
| `maxRetries` | int | 3 | Maximum retry attempts |
| `initialRetryDelayMs` | int | 500 | Initial retry delay |

## API Reference

### `EventTracker`

#### Constructor
```dart
EventTracker({
  required String apiKey,
  required String endpoint,
  int flushIntervalMs = 5000,
  int maxBatchSize = 20,
  int maxQueueSize = 5000,
  bool offlineStorageEnabled = true,
  bool debug = false,
  int maxRetries = 3,
  int initialRetryDelayMs = 500,
})
```

#### Methods

##### `track(String eventName, Map<String, dynamic> properties, {String? userId})`
Track an event.

##### `setUserId(String userId)`
Set global user ID for all subsequent events.

##### `Future<void> flush()`
Manually flush all pending events.

##### `Future<void> dispose()`
Cleanup resources and flush pending events.

##### `TrackerHealth health()`
Get current SDK health status.

## Event Validation

- **Event Name**: Required, max 256 characters
- **Properties**: Must be valid JSON-serializable Map
- **User ID**: Optional, but recommended

Invalid events are dropped with warnings in debug mode.

## Error Handling

The SDK uses custom exceptions:

- `TrackerConfigException`: Invalid configuration
- `TrackerEventException`: Invalid event data
- `TrackerStorageException`: Storage operation failed
- `TrackerNetworkException`: Network operation failed

## Performance

- `track()` completes in < 10ms
- `flush()` completes in < 50ms (non-blocking)
- Runs on background isolate
- Won't block UI thread

## Retry Behavior

Retries on:
- Network errors
- HTTP 408 (Timeout)
- HTTP 429 (Rate Limit)
- HTTP 5xx (Server Error)

Exponential backoff:
- Attempt 1: 0ms delay
- Attempt 2: 500ms delay
- Attempt 3: 1000ms delay
- Attempt 4: 2000ms delay

## License

MIT License - see LICENSE file for details

