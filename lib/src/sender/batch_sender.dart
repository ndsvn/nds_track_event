import 'dart:async';
import 'dart:math';
import '../models/event.dart';
import '../models/tracker_config.dart';
import '../network/http_client.dart';
import '../exceptions/tracker_exceptions.dart';
import '../utils/logger.dart';

/// Handles batch sending of events with retry and exponential backoff
class BatchSender {
  BatchSender({
    required this.config,
    required this.httpClient,
    required this.logger,
  });
  final TrackerConfig config;
  final EventHttpClient httpClient;
  final Logger logger;

  /// Send a batch of events with retry logic
  /// Returns true if successful, false if all retries failed
  Future<bool> sendBatch(List<Event> events) async {
    if (events.isEmpty) {
      return true;
    }

    logger.debug('Attempting to send batch of ${events.length} events');

    int attempt = 0;
    TrackerNetworkException? lastError;

    while (attempt <= config.maxRetries) {
      try {
        // Add delay for retry attempts (exponential backoff)
        if (attempt > 0) {
          final delay = _calculateBackoffDelay(attempt);
          logger.debug('Retry attempt $attempt after ${delay}ms delay');
          await Future.delayed(Duration(milliseconds: delay));
        }

        // Mark events as sending
        for (final event in events) {
          event.status = EventStatus.sending;
        }

        // Attempt to send
        final success = await httpClient.sendBatch(events);

        if (success) {
          // Mark events as sent
          for (final event in events) {
            event.status = EventStatus.sent;
          }
          return true;
        }
      } on TrackerNetworkException catch (e) {
        lastError = e;
        logger.warning('Send attempt $attempt failed: ${e.message}');

        // If error is not retryable, fail immediately
        if (!e.isRetryable) {
          logger.error('Non-retryable error, aborting send');
          // _markEventsFailed(events);
          return false;
        }

        // Update retry count for events
        for (final event in events) {
          event.retryCount = attempt + 1;
        }

        attempt++;
      } catch (e, stackTrace) {
        logger.error('Unexpected error during send: $e',
            error: e, stackTrace: stackTrace);
        attempt++;
      }
    }

    // All retries exhausted
    logger.error('All ${config.maxRetries} retry attempts failed for batch');
    // _markEventsFailed(events);

    if (lastError != null) {
      logger.error('Last error: ${lastError.message}');
    }

    return false;
  }

  /// Calculate exponential backoff delay
  /// Formula: initialDelay * 2^(attempt-1)
  /// Example with initialDelay=500ms:
  /// - Attempt 1: 500ms
  /// - Attempt 2: 1000ms
  /// - Attempt 3: 2000ms
  /// - Attempt 4: 4000ms
  int _calculateBackoffDelay(int attempt) {
    if (attempt <= 0) {
      return 0;
    }

    // Calculate: initialDelay * 2^(attempt-1)
    final delay = config.initialRetryDelayMs * pow(2, attempt - 1);

    // Add jitter (random 0-20% variation) to prevent thundering herd
    final jitter = Random().nextDouble() * 0.2;
    final delayWithJitter = (delay * (1 + jitter)).toInt();

    // Cap at 30 seconds max
    return delayWithJitter > 30000 ? 30000 : delayWithJitter;
  }

  // /// Mark all events in batch as failed
  // void _markEventsFailed(List<Event> events) {
  //   for (final event in events) {
  //     event.status = EventStatus.failed;
  //   }
  // }

  /// Calculate total delay for all retry attempts (for testing/estimation)
  int calculateTotalRetryDelay() {
    int totalDelay = 0;
    for (int i = 1; i <= config.maxRetries; i++) {
      totalDelay += _calculateBackoffDelay(i);
    }
    return totalDelay;
  }
}
