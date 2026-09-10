// KisanSetu (SIH26032) - Notification Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../notification_service.dart';
import '../supabase_service.dart';

/// Abstract repository defining farmer notification and alert operations.
abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications(String farmerId);
  Future<NotificationModel?> createNotification({
    required String farmerId,
    required NotificationType type,
    required String titleEn,
    required String titleHi,
    required String messageEn,
    required String messageHi,
    String? titleTe,
    String? messageTe,
  });
  Future<bool> markNotificationRead(String notificationId);
  Future<int> getUnreadCount(String farmerId);
}

/// Local in-memory implementation of [NotificationRepository].
class LocalNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationModel>> getNotifications(String farmerId) async {
    return NotificationService().notifications;
  }

  @override
  Future<NotificationModel?> createNotification({
    required String farmerId,
    required NotificationType type,
    required String titleEn,
    required String titleHi,
    required String messageEn,
    required String messageHi,
    String? titleTe,
    String? messageTe,
  }) async {
    // Check deduplication
    final existing = NotificationService().notifications;
    final isDuplicate = existing.any((n) =>
        n.type == type && (n.messageEn == messageEn || n.titleEn == titleEn));
    if (isDuplicate) return null;

    final notif = NotificationModel(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      action: _actionForType(type),
      titleEn: titleEn,
      titleHi: titleHi,
      titleTe: titleTe ?? '',
      messageEn: messageEn,
      messageHi: messageHi,
      messageTe: messageTe ?? '',
      timestamp: 'Just now',
      icon: _iconForType(type),
      isRead: false,
    );
    NotificationService().addNotification(notif);
    return notif;
  }

  @override
  Future<bool> markNotificationRead(String notificationId) async {
    NotificationService().markAsRead(notificationId);
    return true;
  }

  @override
  Future<int> getUnreadCount(String farmerId) async {
    return NotificationService().unreadCount;
  }

  static NotificationActionType _actionForType(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
      case NotificationType.checkInConfirmed:
      case NotificationType.slotReallocated:
      case NotificationType.centreChanged:
        return NotificationActionType.myToken;
      case NotificationType.queueUpdated:
      case NotificationType.goodTimeToLeave:
      case NotificationType.centreStatus:
        return NotificationActionType.goTimeDetails;
      case NotificationType.procurementProcessing:
      case NotificationType.procurementAccepted:
        return NotificationActionType.procurementStatus;
      case NotificationType.paymentInitiated:
      case NotificationType.paymentCompleted:
        return NotificationActionType.payment;
      case NotificationType.disputeSubmitted:
        return NotificationActionType.dispute;
    }
  }

  static IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
        return Icons.confirmation_number_rounded;
      case NotificationType.checkInConfirmed:
        return Icons.qr_code_scanner_rounded;
      case NotificationType.slotReallocated:
        return Icons.update_rounded;
      case NotificationType.centreChanged:
        return Icons.alt_route_rounded;
      case NotificationType.queueUpdated:
        return Icons.people_alt_rounded;
      case NotificationType.goodTimeToLeave:
        return Icons.directions_walk_rounded;
      case NotificationType.centreStatus:
        return Icons.store_rounded;
      case NotificationType.procurementProcessing:
        return Icons.scale_rounded;
      case NotificationType.procurementAccepted:
        return Icons.check_circle_rounded;
      case NotificationType.paymentInitiated:
      case NotificationType.paymentCompleted:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.disputeSubmitted:
        return Icons.report_problem_rounded;
    }
  }
}

/// Supabase persistent implementation of [NotificationRepository].
class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<List<NotificationModel>> getNotifications(String farmerId) async {
    if (!_supabase.isReady) {
      return await LocalNotificationRepository().getNotifications(farmerId);
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('notifications')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return await LocalNotificationRepository().getNotifications(farmerId);
      }

      return response.map((row) {
        final type = _parseType(row['type']?.toString());
        return NotificationModel(
          id: row['id'].toString(),
          type: type,
          action: LocalNotificationRepository._actionForType(type),
          titleEn: row['title']?.toString() ?? '',
          titleHi: row['title']?.toString() ?? '',
          messageEn: row['message']?.toString() ?? '',
          messageHi: row['message']?.toString() ?? '',
          timestamp: row['created_at']?.toString() ?? 'Just now',
          icon: LocalNotificationRepository._iconForType(type),
          isRead: row['is_read'] == true,
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseNotificationRepository.getNotifications error: $e');
      return await LocalNotificationRepository().getNotifications(farmerId);
    }
  }

  @override
  Future<NotificationModel?> createNotification({
    required String farmerId,
    required NotificationType type,
    required String titleEn,
    required String titleHi,
    required String messageEn,
    required String messageHi,
    String? titleTe,
    String? messageTe,
  }) async {
    if (!_supabase.isReady) {
      return await LocalNotificationRepository().createNotification(
        farmerId: farmerId,
        type: type,
        titleEn: titleEn,
        titleHi: titleHi,
        messageEn: messageEn,
        messageHi: messageHi,
        titleTe: titleTe,
        messageTe: messageTe,
      );
    }
    try {
      final typeStr = _typeToString(type);
      final existing = await _supabase.client!
          .from('notifications')
          .select()
          .eq('farmer_id', farmerId)
          .eq('type', typeStr)
          .eq('title', titleEn)
          .limit(1);

      if ((existing as List).isNotEmpty) {
        // Deduplicated
        return null;
      }

      final response = await _supabase.client!
          .from('notifications')
          .insert({
            'farmer_id': farmerId,
            'type': typeStr,
            'title': titleEn,
            'message': messageEn,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final createdType = _parseType(response['type']?.toString());
      return NotificationModel(
        id: response['id'].toString(),
        type: createdType,
        action: LocalNotificationRepository._actionForType(createdType),
        titleEn: titleEn,
        titleHi: titleHi,
        titleTe: titleTe ?? '',
        messageEn: messageEn,
        messageHi: messageHi,
        messageTe: messageTe ?? '',
        timestamp: 'Just now',
        icon: LocalNotificationRepository._iconForType(createdType),
        isRead: false,
      );
    } catch (e) {
      debugPrint('SupabaseNotificationRepository.createNotification error: $e');
      return await LocalNotificationRepository().createNotification(
        farmerId: farmerId,
        type: type,
        titleEn: titleEn,
        titleHi: titleHi,
        messageEn: messageEn,
        messageHi: messageHi,
        titleTe: titleTe,
        messageTe: messageTe,
      );
    }
  }

  NotificationType _parseType(String? type) {
    switch (type) {
      case 'booking':
        return NotificationType.bookingConfirmed;
      case 'queue':
        return NotificationType.queueUpdated;
      case 'leave':
        return NotificationType.goodTimeToLeave;
      case 'centre':
        return NotificationType.centreStatus;
      case 'inspection':
        return NotificationType.procurementProcessing;
      case 'accepted':
        return NotificationType.procurementAccepted;
      case 'payment_init':
        return NotificationType.paymentInitiated;
      case 'payment':
        return NotificationType.paymentCompleted;
      case 'dispute':
        return NotificationType.disputeSubmitted;
      case 'reallocated':
      case 'slot_reallocated':
        return NotificationType.slotReallocated;
      case 'centre_changed':
        return NotificationType.centreChanged;
      default:
        return NotificationType.bookingConfirmed;
    }
  }

  String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
        return 'booking';
      case NotificationType.checkInConfirmed:
        return 'booking';
      case NotificationType.queueUpdated:
        return 'queue';
      case NotificationType.goodTimeToLeave:
        return 'leave';
      case NotificationType.centreStatus:
        return 'centre';
      case NotificationType.procurementProcessing:
        return 'inspection';
      case NotificationType.procurementAccepted:
        return 'accepted';
      case NotificationType.paymentInitiated:
        return 'payment_init';
      case NotificationType.paymentCompleted:
        return 'payment';
      case NotificationType.disputeSubmitted:
        return 'dispute';
      case NotificationType.slotReallocated:
        return 'slot_reallocated';
      case NotificationType.centreChanged:
        return 'centre_changed';
    }
  }

  @override
  Future<bool> markNotificationRead(String notificationId) async {
    if (!_supabase.isReady) {
      return await LocalNotificationRepository().markNotificationRead(notificationId);
    }
    try {
      await _supabase.client!
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      debugPrint('SupabaseNotificationRepository.markNotificationRead error: $e');
      return await LocalNotificationRepository().markNotificationRead(notificationId);
    }
  }

  @override
  Future<int> getUnreadCount(String farmerId) async {
    if (!_supabase.isReady) {
      return await LocalNotificationRepository().getUnreadCount(farmerId);
    }
    try {
      final response = await _supabase.client!
          .from('notifications')
          .select()
          .eq('farmer_id', farmerId)
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      debugPrint('SupabaseNotificationRepository.getUnreadCount error: $e');
      return await LocalNotificationRepository().getUnreadCount(farmerId);
    }
  }
}
