import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/app_preferences_service.dart';
import '../services/notification_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import 'farmer_go_time_details_screen.dart';
import 'farmer_my_token_screen.dart';
import 'farmer_payment_screen.dart';
import 'farmer_procurement_status_screen.dart';

/// Screen displaying the Farmer Message Centre and proactive notification history.
class FarmerMessagesScreen extends StatefulWidget {
  final bool isHindi;
  final bool isTelugu;

  const FarmerMessagesScreen({
    super.key,
    this.isHindi = false,
    this.isTelugu = false,
  });

  @override
  State<FarmerMessagesScreen> createState() => _FarmerMessagesScreenState();
}

class _FarmerMessagesScreenState extends State<FarmerMessagesScreen> {
  final NotificationService _notifService = NotificationService();
  final ProcurementStateService _stateService = ProcurementStateService();
  final _prefs = AppPreferencesService.instance;

  bool get _isHindi  => widget.isHindi || (!widget.isTelugu && _prefs.isHindi);
  bool get _isTelugu => widget.isTelugu || (!widget.isHindi && _prefs.isTelugu);

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_rebuild);
    _prefs.addListener(_rebuild);
  }

  @override
  void dispose() {
    _notifService.removeListener(_rebuild);
    _prefs.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  void _speakVoiceSummary() {
    final farmerData = _stateService.farmerData;
    final summary = _notifService.generateVoiceSummary(
      isHindi: _isHindi,
      isTelugu: _isTelugu,
      tokenNumber: farmerData.tokenNumber,
      peopleAhead: farmerData.peopleAhead,
      departureTime: farmerData.recommendedDepartureTime,
    );
    final langCode =
        _isTelugu ? 'te-IN' : (_isHindi ? 'hi-IN' : 'en-IN');
    VoiceAssistantSpeechService.instance.speak(summary, language: langCode);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                summary,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notif) {
    _notifService.markAsRead(notif.id);

    final farmerData = _stateService.farmerData;

    switch (notif.action) {
      case NotificationActionType.myToken:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => FarmerMyTokenScreen(
              data: farmerData,
              isHindi: _isHindi,
              isTelugu: _isTelugu,
            ),
          ),
        );
        break;

      case NotificationActionType.goTimeDetails:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => FarmerGoTimeDetailsScreen(
              data: farmerData,
              isHindi: _isHindi,
              isTelugu: _isTelugu,
            ),
          ),
        );
        break;

      case NotificationActionType.procurementStatus:
      case NotificationActionType.dispute:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => FarmerProcurementStatusScreen(
              isHindi: _isHindi,
              isTelugu: _isTelugu,
            ),
          ),
        );
        break;

      case NotificationActionType.payment:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => FarmerPaymentScreen(
              isHindi: _isHindi,
              isTelugu: _isTelugu,
            ),
          ),
        );
        break;

      case NotificationActionType.none:
        break;
    }
  }

  Color _getBadgeColor(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
      case NotificationType.procurementAccepted:
      case NotificationType.paymentCompleted:
        return AppColors.primaryGreen;
      case NotificationType.centreStatus:
        return AppColors.accentAmber;
      case NotificationType.goodTimeToLeave:
        return const Color(0xFF2E7D32);
      case NotificationType.disputeSubmitted:
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notifService.notifications;
    final unreadCount = _notifService.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          tooltip: _isTelugu
              ? 'వెనుకకు'
              : (_isHindi ? 'पीछे जाएं' : 'Back'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isTelugu
                  ? 'సందేశాలు'
                  : (_isHindi ? 'संदेश' : 'Messages'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              _isTelugu
                  ? '🌾 KisanSetu • సమాచార కేంద్రం'
                  : (_isHindi
                      ? '🌾 KisanSetu • संदेश केंद्र'
                      : '🌾 KisanSetu • Notification Centre'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _speakVoiceSummary,
              icon: const Icon(Icons.volume_up_rounded,
                  size: 20, color: AppColors.primaryGreen),
              label: Text(
                _isTelugu
                    ? 'వినండి'
                    : (_isHindi ? 'सुनें' : 'Listen'),
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top action & unread status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: unreadCount > 0
                          ? AppColors.primaryGreen.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: unreadCount > 0
                            ? AppColors.primaryGreen.withValues(alpha: 0.3)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 16,
                          color: unreadCount > 0
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isTelugu
                              ? '$unreadCount కొత్త సందేశాలు'
                              : (_isHindi
                                  ? '$unreadCount नए संदेश'
                                  : '$unreadCount Unread'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: unreadCount > 0
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: () => _notifService.markAllAsRead(),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: Text(
                        _isTelugu
                            ? 'అన్నీ చదివినట్లు గుర్తించండి'
                            : (_isHindi
                                ? 'सभी पढ़े हुए चिह्नित करें'
                                : 'Mark all as read'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                ],
              ),
            ),

            // Notification List
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isTelugu
                                ? 'ఎటువంటి కొత్త సందేశాలు లేవు'
                                : (_isHindi
                                    ? 'कोई नया संदेश नहीं है'
                                    : 'No notifications yet'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final title = _isTelugu
                            ? notif.titleTe
                            : (_isHindi ? notif.titleHi : notif.titleEn);
                        final message = _isTelugu
                            ? notif.messageTe
                            : (_isHindi ? notif.messageHi : notif.messageEn);
                        final accentColor = _getBadgeColor(notif.type);

                        return Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          elevation: notif.isRead ? 0 : 2,
                          shadowColor: Colors.black12,
                          child: InkWell(
                            onTap: () => _handleNotificationTap(notif),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 64),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: notif.isRead
                                      ? AppColors.cardBorder
                                      : accentColor.withValues(alpha: 0.5),
                                  width: notif.isRead ? 1.0 : 1.8,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon avatar with type tint
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      notif.icon,
                                      color: accentColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Message content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontWeight: notif.isRead
                                                      ? FontWeight.w700
                                                      : FontWeight.w800,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              notif.timestamp,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (!notif.isRead) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: accentColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          message,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.35,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (notif.action !=
                                            NotificationActionType.none) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Text(
                                                _isTelugu
                                                    ? 'వివరాలు చూడండి →'
                                                    : (_isHindi
                                                        ? 'विवरण देखें →'
                                                        : 'View details →'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
