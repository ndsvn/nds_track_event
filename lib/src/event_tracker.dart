import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'models/event.dart';
import 'models/tracker_config.dart';
import 'storage/event_storage.dart';
import 'queue/event_queue.dart';
import 'network/http_client.dart';
import 'sender/batch_sender.dart';
import 'utils/logger.dart';
import 'utils/validators.dart';
import 'utils/uuid_generator.dart';

class EventTracker {
  EventTracker({
    required String apiKey,
    required String endpoint,
    int flushIntervalMs = 5000,
    int maxBatchSize = 20,
    int maxQueueSize = 5000,
    int autoFlushThreshold = 100,
    bool offlineStorageEnabled = true,
    bool debug = false,
    int maxSendRetries = 3,
    int maxTotalQueueSendRetries = 100,
    int maxTotalSendRetries = 600,
    int initialRetryDelayMs = 500,
    int httpTimeoutSeconds = 60,
  }) : config = TrackerConfig(
          apiKey: apiKey,
          endpoint: endpoint,
          flushIntervalMs: flushIntervalMs,
          maxBatchSize: maxBatchSize,
          maxQueueSize: maxQueueSize,
          autoFlushThreshold: autoFlushThreshold,
          offlineStorageEnabled: offlineStorageEnabled,
          debug: debug,
          maxSendRetries: maxSendRetries,
          maxTotalQueueSendRetries: maxTotalQueueSendRetries,
          maxTotalSendRetries: maxTotalSendRetries,
          initialRetryDelayMs: initialRetryDelayMs,
          httpTimeoutSeconds: httpTimeoutSeconds,
        ) {
    _initialize();
  }

  final TrackerConfig config;
  late final Logger _logger;
  late final EventStorage _storage;
  late final EventQueue _queue;
  late final EventHttpClient _httpClient;
  late final BatchSender _batchSender;

  Timer? _flushTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isDisposed = false;

  String? _globalUserId;

  bool _isOnline = true;

  /// Initialize the tracker
  Future<void> _initialize() async {
    try {
      // Validate configuration
      config.validate();

      // Initialize logger
      _logger = Logger(isDebug: config.debug);
      _logger.info('Initializing EventTracker SDK');

      // Initialize HTTP client
      _httpClient = EventHttpClient(config: config, logger: _logger);

      // Initialize batch sender
      _batchSender = BatchSender(
        config: config,
        httpClient: _httpClient,
        logger: _logger,
      );

      // Initialize queue
      _queue = EventQueue(
        maxSize: config.maxQueueSize,
        onEventDropped: (event) {
          _logger.warning('Event dropped due to full queue: ${event.name}');
        },
        onEventAdded: (event) {
          _logger.debug('Event added to queue: ${event.name}');
        },
      );

      // Initialize storage if enabled
      if (config.offlineStorageEnabled) {
        _storage = EventStorage();
        await _storage.init();
        _logger.info('Storage initialized');

        // Load pending events from storage
        await _loadPendingEvents();
      }

      // Start connectivity monitoring
      _startConnectivityMonitoring();

      // Start flush timer
      _startFlushTimer();

      // Listen to app lifecycle
      _setupLifecycleListener();
      _logger.info('EventTracker initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize EventTracker',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Track an event
  void track(
    String eventName,
    Map<String, dynamic> properties, {
    String? userId,
  }) {
    if (_isDisposed) {
      _logger.warning('Cannot track event after dispose');
      return;
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Validate event name
      final nameError = EventValidator.validateEventName(
        eventName,
        config.maxEventNameLength,
      );

      if (nameError != null) {
        _logger.warning('Invalid event name: $nameError');
        // Sanitize the name instead of dropping
        eventName = EventValidator.sanitizeEventName(
          eventName,
          config.maxEventNameLength,
        );
      }

      // Validate properties
      final propsError = EventValidator.validateProperties(properties);
      if (propsError != null) {
        _logger.warning('Invalid properties: $propsError');
        // Sanitize properties instead of dropping
        properties = EventValidator.sanitizeProperties(properties);
      }

      // Use global user ID if not provided
      final effectiveUserId = userId ?? _globalUserId;

      // Create event
      final event = Event(
        id: UuidGenerator.generate(),
        name: eventName,
        properties: properties,
        userId: effectiveUserId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // Add to queue
      final added = _queue.enqueue(event);

      if (added) {
        // Save to storage if enabled
        if (config.offlineStorageEnabled) {
          _storage.saveEvent(event).catchError((e) {
            _logger.error('Failed to save event to storage', error: e);
          });
        }

        // Check if queue size exceeds threshold for auto-flush
        if (_queue.size >= config.autoFlushThreshold) {
          _logger.debug(
              'Queue size (${_queue.size}) exceeds threshold (${config.autoFlushThreshold}), triggering auto-flush');
          _performFlush();
        }
      }

      stopwatch.stop();
      _logger.debug('track() completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      _logger.error('Error tracking event', error: e, stackTrace: stackTrace);
    }
  }

  /// Set global user ID for all subsequent events
  void setUserId(String userId) {
    try {
      final error = EventValidator.validateUserId(userId);
      if (error != null) {
        _logger.warning('Invalid user ID: $error');
        return;
      }

      _globalUserId = userId;
      _logger.info('Global user ID set: $userId');
    } catch (e) {
      _logger.error('Error setting user ID', error: e);
    }
  }

  /// Manually flush all pending events
  Future<void> flush() async {
    if (_isDisposed) {
      _logger.warning('Cannot flush after dispose');
      return;
    }

    try {
      final stopwatch = Stopwatch()..start();
      _logger.debug('Manual flush triggered');

      await _performFlush();

      stopwatch.stop();
      _logger.debug('flush() completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      _logger.error('Error during flush', error: e, stackTrace: stackTrace);
    }
  }

  /// Dispose and cleanup resources
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _logger.info('Disposing EventTracker');
    _isDisposed = true;

    try {
      // Stop flush timer
      _flushTimer?.cancel();
      _flushTimer = null;

      // Stop connectivity monitoring
      await _connectivitySubscription?.cancel();
      _connectivitySubscription = null;

      // Flush any pending events
      await _performFlush();

      // Close queue
      _queue.dispose();

      // Close storage
      if (config.offlineStorageEnabled) {
        await _storage.close();
      }

      // Close HTTP client
      _httpClient.close();

      _logger.info('EventTracker disposed successfully');
    } catch (e, stackTrace) {
      _logger.error('Error during dispose', error: e, stackTrace: stackTrace);
    }
  }

  /// Start the periodic flush timer
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      Duration(milliseconds: config.flushIntervalMs),
      (_) => _performFlush(),
    );
    _logger
        .debug('Flush timer started (interval: ${config.flushIntervalMs}ms)');
  }

  /// Perform the actual flush operation
  /// This will send ALL pending events in batches of maxBatchSize
  Future<void> _performFlush() async {
    if (_queue.isEmpty || !_isOnline) {
      return;
    }

    try {
      final totalEvents = _queue.size;
      _logger.debug('Starting flush for $totalEvents events');

      int successCount = 0;
      int failCount = 0;

      // Keep flushing batches until queue is empty
      while (!_queue.isEmpty && _isOnline) {
        // Get batch of events from queue
        final batch = _queue.dequeueBatch(config);
        if (batch.isEmpty) {
          break;
        }
        // Send batch
        final success = await _batchSender.sendBatch(batch);

        if (success) {
          successCount += batch.length;

          // Delete from storage if enabled
          if (config.offlineStorageEnabled) {
            final eventIds = batch.map((e) => e.id).toList();
            await _storage.deleteEvents(eventIds);
          }

          _logger.debug('Successfully sent batch of ${batch.length} events');
        } else {
          failCount += batch.length;

          // Requeue failed events
          _queue.requeueAllToFront(batch);

          // Save failed events to storage if enabled
          if (config.offlineStorageEnabled) {
            List<Event> failedEvents = batch.where((e) => e.retryCount >= config.maxTotalSendRetries).toList();
            List<Event> notFailedEvents = batch.where((e) => e.retryCount < config.maxTotalSendRetries).toList();
            await _storage.saveEvents(notFailedEvents);
            await _storage.deleteEvents(failedEvents.map((e) => e.id).toList());
          }

          _logger.error(
              'Failed to flush batch of ${batch.length} events, requeued');

          // Stop flushing on first failure to avoid hammering the server
          break;
        }
      }

      if (successCount > 0) {
        _logger.info('Flush completed: $successCount events sent successfully');
      }

      if (failCount > 0) {
        _logger
            .warning('Flush completed with failures: $failCount events failed');
      }
    } catch (e, stackTrace) {
      _logger.error('Error during flush', error: e, stackTrace: stackTrace);
    }
  }

  /// Load pending events from storage into queue
  Future<void> _loadPendingEvents() async {
    try {
      final pendingEvents = await _storage.getPendingEvents();
      if (pendingEvents.isNotEmpty) {
        final added = _queue.enqueueAll(pendingEvents);
        _logger.info('Loaded $added pending events from storage');
      }
    } catch (e, stackTrace) {
      _logger.error('Error loading pending events',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Start monitoring network connectivity
  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      // _isOnline = result != ConnectivityResult.none;

      _logger.debug('Connectivity changed: online=$_isOnline');

      if (!wasOnline && _isOnline) {
        _logger.info('Back online, triggering flush');
        _performFlush();
      }
    });
  }

  /// Setup app lifecycle listener
  void _setupLifecycleListener() {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
  }
}

/// App lifecycle observer to handle background/foreground transitions
class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver(this.tracker);
  final EventTracker tracker;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App going to background, flush events
      tracker._logger.debug('App going to background, flushing events');
      tracker.flush();
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground
      tracker._logger.debug('App resumed');
      if (tracker.config.offlineStorageEnabled) {
        tracker._loadPendingEvents();
      }
    }
  }
}
