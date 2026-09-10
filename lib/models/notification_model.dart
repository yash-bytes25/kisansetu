import 'package:flutter/material.dart';

/// Categories of prototype notifications in KisanSetu.
enum NotificationType {
  bookingConfirmed,
  queueUpdated,
  goodTimeToLeave,
  centreStatus,
  procurementProcessing,
  procurementAccepted,
  paymentInitiated,
  paymentCompleted,
  disputeSubmitted,
  checkInConfirmed,
  slotReallocated,
  centreChanged,
}

/// Navigation destination triggered by tapping a notification.
enum NotificationActionType {
  myToken,
  goTimeDetails,
  procurementStatus,
  payment,
  dispute,
  none,
}

/// In-memory prototype notification model for the KisanSetu Farmer Message Centre.
class NotificationModel {
  final String id;
  final NotificationType type;
  final NotificationActionType action;
  final String titleEn;
  final String titleHi;
  final String titleTe;
  final String messageEn;
  final String messageHi;
  final String messageTe;
  final String timestamp;
  final IconData icon;
  final String? tokenNumber;
  final Map<String, dynamic>? metadata;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.action,
    required this.titleEn,
    required this.titleHi,
    this.titleTe = '',
    required this.messageEn,
    required this.messageHi,
    this.messageTe = '',
    required this.timestamp,
    required this.icon,
    this.tokenNumber,
    this.metadata,
    this.isRead = false,
  });

  /// Creates a copy with specified fields modified.
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    NotificationActionType? action,
    String? titleEn,
    String? titleHi,
    String? titleTe,
    String? messageEn,
    String? messageHi,
    String? messageTe,
    String? timestamp,
    IconData? icon,
    String? tokenNumber,
    Map<String, dynamic>? metadata,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      action: action ?? this.action,
      titleEn: titleEn ?? this.titleEn,
      titleHi: titleHi ?? this.titleHi,
      titleTe: titleTe ?? (this.titleTe.isNotEmpty ? this.titleTe : (titleEn ?? this.titleEn)),
      messageEn: messageEn ?? this.messageEn,
      messageHi: messageHi ?? this.messageHi,
      messageTe: messageTe ?? (this.messageTe.isNotEmpty ? this.messageTe : (messageEn ?? this.messageEn)),
      timestamp: timestamp ?? this.timestamp,
      icon: icon ?? this.icon,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
    );
  }
}
