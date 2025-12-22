# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-17

### Added
- Initial release of NDS Track Event SDK
- Event tracking with `track()` method
- SQLite-based offline storage
- In-memory FIFO queue for events
- Automatic batch sending with configurable intervals
- Retry logic with exponential backoff
- Network connectivity monitoring
- App lifecycle handling (background/foreground)
- Manual flush capability
- Global user ID support
- Health monitoring API
- Comprehensive error handling with custom exception types
- Debug logging support
- Event validation and sanitization
- Thread-safe queue operations

### Features
- Non-blocking event tracking (< 10ms)
- Automatic retry on network failures
- Offline event persistence
- Configurable batch size and intervals
- Queue overflow handling
- Background event processing
- Graceful disposal and cleanup

### Performance
- Fast event tracking (< 10ms)
- Efficient batch sending (< 50ms)
- Background operation without UI blocking
- Optimized SQLite operations
- Memory-efficient queue management

