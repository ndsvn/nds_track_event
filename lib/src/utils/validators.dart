import 'dart:convert';

/// Utility class for validating event data
class EventValidator {
  /// Validate event name
  /// Returns null if valid, error message if invalid
  static String? validateEventName(String? name, int maxLength) {
    if (name == null || name.isEmpty) {
      return 'Event name cannot be empty';
    }

    if (name.length > maxLength) {
      return 'Event name too long (max: $maxLength, got: ${name.length})';
    }

    return null;
  }

  /// Validate and sanitize event name
  /// Truncates if too long, returns cleaned name
  static String sanitizeEventName(String name, int maxLength) {
    if (name.length > maxLength) {
      return name.substring(0, maxLength);
    }
    return name;
  }

  /// Validate event properties (must be JSON-serializable)
  /// Returns null if valid, error message if invalid
  static String? validateProperties(Map<String, dynamic>? properties) {
    if (properties == null) {
      return null;
    }

    try {
      // Try to encode to JSON to verify it's serializable
      jsonEncode(properties);
      return null;
    } catch (e) {
      return 'Properties must be JSON-serializable: $e';
    }
  }

  /// Sanitize properties by removing non-JSON-serializable values
  /// Returns a cleaned version of the properties map
  static Map<String, dynamic> sanitizeProperties(Map<String, dynamic> properties) {
    final sanitized = <String, dynamic>{};

    for (final entry in properties.entries) {
      try {
        // Try to encode the value
        jsonEncode(entry.value);
        sanitized[entry.key] = entry.value;
      } catch (e) {
        // Skip non-serializable values
        continue;
      }
    }

    return sanitized;
  }

  /// Validate user ID
  /// Returns null if valid, error message if invalid
  static String? validateUserId(String? userId) {
    if (userId == null) {
      return null;
    }

    if (userId.isEmpty) {
      return 'User ID cannot be empty string';
    }

    if (userId.length > 256) {
      return 'User ID too long (max: 256, got: ${userId.length})';
    }

    return null;
  }
}

