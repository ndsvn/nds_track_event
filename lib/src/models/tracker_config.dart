/// Configuration for the EventTracker SDK
class TrackerConfig {
  const TrackerConfig({
    required this.apiKey,
    required this.endpoint,
    this.flushIntervalMs = 5000,
    this.maxBatchSize = 20,
    this.maxQueueSize = 5000,
    this.autoFlushThreshold = 100,
    this.offlineStorageEnabled = true,
    this.debug = false,
    this.maxRetries = 3,
    this.initialRetryDelayMs = 500,
    this.maxEventNameLength = 256,
    this.httpTimeoutSeconds = 30,
  });

  /// API key for authentication
  final String apiKey;

  /// Endpoint URL for batch event submission
  final String endpoint;

  /// Auto-flush interval in milliseconds (default: 5000ms = 5s)
  final int flushIntervalMs;

  /// Maximum number of events per batch (default: 20)
  final int maxBatchSize;

  /// Maximum in-memory queue size (default: 5000)
  final int maxQueueSize;

  /// Queue size threshold to trigger automatic flush (default: 100)
  /// When queue size exceeds this value, all pending events will be sent
  final int autoFlushThreshold;

  /// Enable offline storage with SQLite (default: true)
  final bool offlineStorageEnabled;

  /// Enable debug logging (default: false)
  final bool debug;

  /// Maximum retry attempts for failed requests (default: 3)
  final int maxRetries;

  /// Initial retry delay in milliseconds (default: 500ms)
  final int initialRetryDelayMs;

  /// Maximum event name length (default: 256)
  final int maxEventNameLength;

  /// Timeout for HTTP requests in seconds (default: 30)
  final int httpTimeoutSeconds;

  /// Validate configuration and throw exception if invalid
  void validate() {
    if (apiKey.isEmpty) {
      throw ArgumentError('apiKey cannot be empty');
    }

    if (endpoint.isEmpty) {
      throw ArgumentError('endpoint cannot be empty');
    }

    if (!endpoint.startsWith('http://') && !endpoint.startsWith('https://')) {
      throw ArgumentError('endpoint must start with http:// or https://');
    }

    if (maxBatchSize < 1) {
      throw ArgumentError('maxBatchSize must be at least 1');
    }

    if (maxQueueSize < maxBatchSize) {
      throw ArgumentError('maxQueueSize must be >= maxBatchSize');
    }

    if (autoFlushThreshold < 1) {
      throw ArgumentError('autoFlushThreshold must be at least 1');
    }

    if (autoFlushThreshold > maxQueueSize) {
      throw ArgumentError('autoFlushThreshold must be <= maxQueueSize');
    }

    if (maxRetries < 0) {
      throw ArgumentError('maxRetries must be >= 0');
    }

    if (initialRetryDelayMs < 0) {
      throw ArgumentError('initialRetryDelayMs must be >= 0');
    }

    if (maxEventNameLength < 1) {
      throw ArgumentError('maxEventNameLength must be at least 1');
    }

    if (httpTimeoutSeconds < 1) {
      throw ArgumentError('httpTimeoutSeconds must be at least 1');
    }
  }

  /// Create a copy of this config with updated fields
  TrackerConfig copyWith({
    String? apiKey,
    String? endpoint,
    int? flushIntervalMs,
    int? maxBatchSize,
    int? maxQueueSize,
    int? autoFlushThreshold,
    bool? offlineStorageEnabled,
    bool? debug,
    int? maxRetries,
    int? initialRetryDelayMs,
    int? maxEventNameLength,
    int? httpTimeoutSeconds,
  }) {
    return TrackerConfig(
      apiKey: apiKey ?? this.apiKey,
      endpoint: endpoint ?? this.endpoint,
      flushIntervalMs: flushIntervalMs ?? this.flushIntervalMs,
      maxBatchSize: maxBatchSize ?? this.maxBatchSize,
      maxQueueSize: maxQueueSize ?? this.maxQueueSize,
      autoFlushThreshold: autoFlushThreshold ?? this.autoFlushThreshold,
      offlineStorageEnabled:
          offlineStorageEnabled ?? this.offlineStorageEnabled,
      debug: debug ?? this.debug,
      maxRetries: maxRetries ?? this.maxRetries,
      initialRetryDelayMs: initialRetryDelayMs ?? this.initialRetryDelayMs,
      maxEventNameLength: maxEventNameLength ?? this.maxEventNameLength,
      httpTimeoutSeconds: httpTimeoutSeconds ?? this.httpTimeoutSeconds,
    );
  }

  @override
  String toString() {
    return 'TrackerConfig{endpoint: $endpoint, flushIntervalMs: $flushIntervalMs, '
        'maxBatchSize: $maxBatchSize, maxQueueSize: $maxQueueSize, '
        'autoFlushThreshold: $autoFlushThreshold, '
        'offlineStorageEnabled: $offlineStorageEnabled, debug: $debug}';
  }
}
