import 'dart:async';
import 'package:flutter/material.dart';

/// Notification service for system alerts and warnings
/// Monitors telemetry data and triggers notifications
class NotificationService {
  // Notification thresholds
  static const double lowBatteryThreshold = 20.0;
  static const double criticalBatteryThreshold = 10.0;
  static const double highTempThreshold = 35.0;
  static const double criticalTempThreshold = 40.0;

  // Notification history
  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _notificationController =
      StreamController<AppNotification>.broadcast();

  // Cooldown to prevent spam (in seconds)
  final Map<String, DateTime> _lastNotificationTime = {};
  static const int notificationCooldown = 60; // 1 minute

  /// Stream of notifications
  Stream<AppNotification> get notificationStream =>
      _notificationController.stream;

  /// Get all notifications
  List<AppNotification> get notifications => _notifications;

  /// Get unread notification count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Check telemetry data and trigger notifications if needed
  void checkTelemetry(Map<String, dynamic> telemetry) {
    // Check battery level
    final batterySoc = telemetry['battery_soc']?.toDouble() ?? 100.0;
    if (batterySoc <= criticalBatteryThreshold) {
      _triggerNotification(
        'Critical Battery Level',
        'Battery at ${batterySoc.toStringAsFixed(0)}%. Charge immediately!',
        NotificationType.critical,
        'battery_critical',
      );
    } else if (batterySoc <= lowBatteryThreshold) {
      _triggerNotification(
        'Low Battery',
        'Battery at ${batterySoc.toStringAsFixed(0)}%. Consider charging soon.',
        NotificationType.warning,
        'battery_low',
      );
    }

    // Check battery temperature
    final batteryTemp = telemetry['battery_temp']?.toDouble() ?? 25.0;
    if (batteryTemp >= criticalTempThreshold) {
      _triggerNotification(
        'Critical Temperature',
        'Battery temperature at ${batteryTemp.toStringAsFixed(1)}°C. Stop vehicle!',
        NotificationType.critical,
        'temp_critical',
      );
    } else if (batteryTemp >= highTempThreshold) {
      _triggerNotification(
        'High Temperature',
        'Battery temperature at ${batteryTemp.toStringAsFixed(1)}°C. Reduce load.',
        NotificationType.warning,
        'temp_high',
      );
    }

    // Check tire pressure
    final tirePressure = telemetry['tire_pressure'];
    if (tirePressure != null) {
      final frontLeft = tirePressure['front_left']?.toDouble() ?? 35.0;
      final frontRight = tirePressure['front_right']?.toDouble() ?? 35.0;
      final rearLeft = tirePressure['rear_left']?.toDouble() ?? 35.0;
      final rearRight = tirePressure['rear_right']?.toDouble() ?? 35.0;

      const lowPressureThreshold = 30.0;
      if (frontLeft < lowPressureThreshold ||
          frontRight < lowPressureThreshold ||
          rearLeft < lowPressureThreshold ||
          rearRight < lowPressureThreshold) {
        _triggerNotification(
          'Low Tire Pressure',
          'One or more tires have low pressure. Check tires.',
          NotificationType.warning,
          'tire_pressure',
        );
      }
    }
  }

  /// Trigger a notification with cooldown
  void _triggerNotification(
    String title,
    String message,
    NotificationType type,
    String id,
  ) {
    // Check cooldown
    final lastTime = _lastNotificationTime[id];
    if (lastTime != null) {
      final elapsed = DateTime.now().difference(lastTime).inSeconds;
      if (elapsed < notificationCooldown) {
        return; // Still in cooldown
      }
    }

    // Create notification
    final notification = AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    // Add to history
    _notifications.insert(0, notification); // Add to beginning

    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }

    // Update cooldown
    _lastNotificationTime[id] = DateTime.now();

    // Broadcast notification
    _notificationController.add(notification);
  }

  /// Mark notification as read
  void markAsRead(String id) {
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => AppNotification(
        id: '',
        title: '',
        message: '',
        type: NotificationType.info,
        timestamp: DateTime.now(),
      ),
    );
    notification.isRead = true;
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
  }

  /// Dispose
  void dispose() {
    _notificationController.close();
  }
}

/// Notification type enum
enum NotificationType { info, warning, critical }

/// Notification model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  /// Get icon for notification type
  IconData get icon {
    switch (type) {
      case NotificationType.info:
        return Icons.info;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.critical:
        return Icons.error;
    }
  }

  /// Get color for notification type
  Color get color {
    switch (type) {
      case NotificationType.info:
        return Colors.blueAccent;
      case NotificationType.warning:
        return Colors.orangeAccent;
      case NotificationType.critical:
        return Colors.redAccent;
    }
  }
}
