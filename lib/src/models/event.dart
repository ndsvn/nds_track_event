import 'dart:convert';

/// Represents a trackable event with metadata
class Event {
  Event({
    required this.id,
    required this.name,
    required this.properties,
    this.userId,
    required this.timestamp,
    this.retryCount = 0,
    this.status = EventStatus.pending,
  });

  /// Unique identifier for the event (UUID)
  final String id;

  /// Event name/type (e.g., "button_clicked", "purchase")
  final String name;

  /// Event properties as JSON-serializable map
  final Map<String, dynamic> properties;

  /// User ID associated with the event
  final String? userId;

  /// Timestamp when event was created (milliseconds since epoch)
  final int timestamp;

  /// Number of retry attempts for this event
  int retryCount;

  /// Status of the event
  EventStatus status;

  /// Create an Event from JSON map
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      name: json['name'] as String,
      properties: json['properties'] is String
          ? jsonDecode(json['properties'] as String) as Map<String, dynamic>
          : json['properties'] as Map<String, dynamic>,
      userId: json['userId'] as String?,
      timestamp: json['timestamp'] as int,
      retryCount: json['retryCount'] as int? ?? 0,
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == 'EventStatus.${json['status']}',
        orElse: () => EventStatus.pending,
      ),
    );
  }

  /// Convert Event to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'properties': properties,
      'userId': userId,
      'timestamp': timestamp,
      'retryCount': retryCount,
      'status': status.toString().split('.').last,
    };
  }

  /// Convert Event to JSON map for database storage
  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'name': name,
      'properties': jsonEncode(properties),
      'userId': userId,
      'timestamp': timestamp,
      'retryCount': retryCount,
      'status': status.toString().split('.').last,
    };
  }

  /// Convert Event to JSON map for API submission
  Map<String, dynamic> toApiJson() {
    if(userId != null) {
      return {
      ...properties,
      'EventName': name,
    };
    }
    return {
      ...properties,
      'UserId': userId,
      'EventName': name,
    };
  }

  /// Create a copy of this event with updated fields
  Event copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? properties,
    String? userId,
    int? timestamp,
    int? retryCount,
    EventStatus? status,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      properties: properties ?? this.properties,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Event{id: $id, name: $name, userId: $userId, timestamp: $timestamp, status: $status}';
  }
}

/// Event status enum
enum EventStatus {
  /// Event is pending to be sent
  pending,

  /// Event is currently being sent
  sending,

  /// Event was successfully sent
  sent,

  // /// Event failed to send after all retries
  // failed,
}
