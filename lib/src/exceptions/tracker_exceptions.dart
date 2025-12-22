/// Base exception class for all tracker exceptions
abstract class TrackerException implements Exception {
  const TrackerException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// Exception thrown when tracker configuration is invalid
class TrackerConfigException extends TrackerException {
  const TrackerConfigException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Exception thrown when event data is invalid
class TrackerEventException extends TrackerException {
  const TrackerEventException(
    super.message, {
    this.eventName,
    super.originalError,
    super.stackTrace,
  });
  final String? eventName;

  @override
  String toString() {
    final buffer = StringBuffer('TrackerEventException: $message');
    if (eventName != null) {
      buffer.write(' (eventName: $eventName)');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// Exception thrown when storage operations fail
class TrackerStorageException extends TrackerException {
  const TrackerStorageException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Exception thrown when network operations fail
class TrackerNetworkException extends TrackerException {
  const TrackerNetworkException(
    super.message, {
    this.statusCode,
    this.isRetryable = false,
    super.originalError,
    super.stackTrace,
  });
  final int? statusCode;
  final bool isRetryable;

  /// Check if this error should trigger a retry
  static bool shouldRetry(int? statusCode) {
    if (statusCode == null) return true; // Network error, should retry

    // Retry on specific status codes
    return statusCode == 408 || // Request Timeout
        statusCode == 429 || // Too Many Requests
        (statusCode >= 500 && statusCode < 600); // Server errors
  }

  @override
  String toString() {
    final buffer = StringBuffer('TrackerNetworkException: $message');
    if (statusCode != null) {
      buffer.write(' (statusCode: $statusCode)');
    }
    buffer.write(' [retryable: $isRetryable]');
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// Exception thrown when initialization fails
class TrackerInitializationException extends TrackerException {
  const TrackerInitializationException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}
