import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../models/tracker_config.dart';
import '../exceptions/tracker_exceptions.dart';
import '../utils/logger.dart';

/// HTTP client for sending events to the ingestion API
class EventHttpClient {
  EventHttpClient({
    required this.config,
    required this.logger,
    http.Client? client,
  }) : _client = client ?? http.Client();
  final TrackerConfig config;
  final Logger logger;
  final http.Client _client;

  /// Send a batch of events to the API
  /// Returns true if successful, throws TrackerNetworkException on failure
  Future<bool> sendBatch(List<Event> events) async {
    if (events.isEmpty) {
      return true;
    }
    final startTime = DateTime.now();
    logger.debug('Sending batch of ${events.length} events to ${config.endpoint}');
    try {
      // Send HTTP request
      final response = await _client
          .post(
            Uri.parse(config.endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': config.apiKey,
            },
            body: jsonEncode(events.map((e) => e.toApiJson()).toList()),
          )
          .timeout(Duration(seconds: config.httpTimeoutSeconds));

      final duration = DateTime.now().difference(startTime);
      logger.debug('Response status: ${response.statusCode} (${duration.inMilliseconds}ms)');

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.info('Successfully sent ${events.length} events');
        return true;
      }

      // Check if error is retryable
      final isRetryable = TrackerNetworkException.shouldRetry(response.statusCode);

      throw TrackerNetworkException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        statusCode: response.statusCode,
        isRetryable: isRetryable,
        originalError: response.body,
      );
    } on TimeoutException catch (e, stackTrace) {
      logger.warning('Request timeout after ${config.httpTimeoutSeconds}s');
      throw TrackerNetworkException(
        'Request timeout',
        isRetryable: true,
        originalError: e,
        stackTrace: stackTrace,
      );
    } on http.ClientException catch (e, stackTrace) {
      logger.warning('HTTP client error: $e');
      throw TrackerNetworkException(
        'HTTP client error: ${e.message}',
        isRetryable: true,
        originalError: e,
        stackTrace: stackTrace,
      );
    } on TrackerNetworkException {
      rethrow;
    } catch (e, stackTrace) {
      logger.error('Unexpected error sending batch: $e');
      throw TrackerNetworkException(
        'Unexpected error: $e',
        isRetryable: true,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Close the HTTP client
  void close() {
    _client.close();
  }
}

