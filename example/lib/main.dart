import 'package:flutter/material.dart';
import 'package:nds_track_event/nds_track_event.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NDS Track Event Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const EventTrackerDemo(),
    );
  }
}

class EventTrackerDemo extends StatefulWidget {
  const EventTrackerDemo({super.key});

  @override
  State<EventTrackerDemo> createState() => _EventTrackerDemoState();
}

class _EventTrackerDemoState extends State<EventTrackerDemo> {
  late EventTracker _tracker;

  int _eventCount = 0;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeTracker();
  }

  void _initializeTracker() {
    try {
      _tracker = EventTracker(
        apiKey: 'demo-api-key',
        endpoint: 'https://api.example.com/v1/events/batch',
        flushIntervalMs: 5000,
        maxBatchSize: 20,
        maxQueueSize: 5000,
        offlineStorageEnabled: true,
        debug: true,
      );

      // Set a user ID
      _tracker.setUserId('demo-user-123');

      setState(() {
        _status = 'Tracker initialized';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _trackSimpleEvent() {
    _tracker.track('button_clicked', {
      'button_name': 'demo_button',
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() {
      _eventCount++;
      _status = 'Tracked simple event';

    });
  }

  void _trackPurchaseEvent() {
    _tracker.track('purchase', {
      'product_id': 'prod_${DateTime.now().millisecondsSinceEpoch}',
      'product_name': 'Demo Product',
      'amount': 99.99,
      'currency': 'USD',
      'quantity': 1,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() {
      _eventCount++;
      _status = 'Tracked purchase event';

    });
  }

  void _trackCustomEvent() {
    _tracker.track('custom_event', {
      'custom_field_1': 'value 1',
      'custom_field_2': 123,
      'custom_field_3': true,
      'nested': {
        'field_a': 'nested value',
        'field_b': [1, 2, 3],
      },
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() {
      _eventCount++;
      _status = 'Tracked custom event';
    
    });
  }

  Future<void> _flushEvents() async {
    setState(() {
      _status = 'Flushing events...';
    });

    await _tracker.flush();

    setState(() {
      _status = 'Events flushed';

    });
  }

  void _trackMultipleEvents() {
    for (int i = 0; i < 10; i++) {
      _tracker.track('batch_event_$i', {
        'event_number': i,
        'batch_id': DateTime.now().millisecondsSinceEpoch,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    setState(() {
      _eventCount += 10;
      _status = 'Tracked 10 events';

    });
  }

  @override
  void dispose() {
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('NDS Track Event Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 4),
                    Text('Events tracked this session: $_eventCount'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Health Card
            const SizedBox(height: 16),

            // Action Buttons
            const Text(
              'Track Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _trackSimpleEvent,
              child: const Text('Track Simple Event'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _trackPurchaseEvent,
              child: const Text('Track Purchase Event'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _trackCustomEvent,
              child: const Text('Track Custom Event'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _trackMultipleEvents,
              child: const Text('Track 10 Events'),
            ),
            const SizedBox(height: 16),

            // Control Buttons
            const Text(
              'Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _flushEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Flush Events Now'),
            ),
            const SizedBox(height: 8),
           
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}

