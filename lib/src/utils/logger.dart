import 'package:flutter/foundation.dart';

/// Simple logger for SDK internal logging
class Logger {
  const Logger({
    required this.isDebug,
    this.prefix = '[NDS-Track-Event]',
  });
  final bool isDebug;
  final String prefix;

  /// Log debug message (only in debug mode)
  void debug(String message) {
    if (isDebug && kDebugMode) {
      debugPrint('$prefix [DEBUG] $message');
    }
  }

  /// Log info message
  void info(String message) {
    if (isDebug && kDebugMode) {
      debugPrint('$prefix [INFO] $message');
    }
  }

  /// Log warning message
  void warning(String message) {
    if (isDebug && kDebugMode) {
      debugPrint('$prefix [WARNING] $message');
    }
  }

  /// Log error message
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('$prefix [ERROR] $message');
      if (error != null) {
        debugPrint('$prefix [ERROR] Error: $error');
      }
      if (stackTrace != null && isDebug) {
        debugPrint('$prefix [ERROR] Stack trace: $stackTrace');
      }
    }
  }
}
