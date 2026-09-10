// KisanSetu (SIH26032) - Repository Provider
// Central provider giving access to the active repository implementations based on BackendMode.

import '../../config/supabase_config.dart';
import 'booking_repository.dart';
import 'dispute_repository.dart';
import 'farmer_repository.dart';
import 'notification_repository.dart';
import 'payment_repository.dart';
import 'procurement_centre_repository.dart';
import 'procurement_repository.dart';
import 'queue_repository.dart';

/// Central provider that dispenses the appropriate repository implementations
/// based on the active [BackendMode].
class RepositoryProvider {
  RepositoryProvider._();

  // Cached Local implementations
  static final FarmerRepository _localFarmer = LocalFarmerRepository();
  static final ProcurementCentreRepository _localCentre = LocalProcurementCentreRepository();
  static final BookingRepository _localBooking = LocalBookingRepository();
  static final QueueRepository _localQueue = LocalQueueRepository();
  static final ProcurementRepository _localProcurement = LocalProcurementRepository();
  static final PaymentRepository _localPayment = LocalPaymentRepository();
  static final NotificationRepository _localNotification = LocalNotificationRepository();
  static final DisputeRepository _localDispute = LocalDisputeRepository();

  // Cached Supabase implementations
  static final FarmerRepository _supabaseFarmer = SupabaseFarmerRepository();
  static final ProcurementCentreRepository _supabaseCentre = SupabaseProcurementCentreRepository();
  static final BookingRepository _supabaseBooking = SupabaseBookingRepository();
  static final QueueRepository _supabaseQueue = SupabaseQueueRepository();
  static final ProcurementRepository _supabaseProcurement = SupabaseProcurementRepository();
  static final PaymentRepository _supabasePayment = SupabasePaymentRepository();
  static final NotificationRepository _supabaseNotification = SupabaseNotificationRepository();
  static final DisputeRepository _supabaseDispute = SupabaseDisputeRepository();

  // Optional test overrides
  static FarmerRepository? _farmerOverride;
  static ProcurementCentreRepository? _centreOverride;
  static BookingRepository? _bookingOverride;
  static QueueRepository? _queueOverride;
  static ProcurementRepository? _procurementOverride;
  static PaymentRepository? _paymentOverride;
  static NotificationRepository? _notificationOverride;
  static DisputeRepository? _disputeOverride;

  /// Resets all test overrides.
  static void resetOverrides() {
    _farmerOverride = null;
    _centreOverride = null;
    _bookingOverride = null;
    _queueOverride = null;
    _procurementOverride = null;
    _paymentOverride = null;
    _notificationOverride = null;
    _disputeOverride = null;
  }

  // Setters for test mocks
  static void setFarmerRepository(FarmerRepository repo) => _farmerOverride = repo;
  static void setCentreRepository(ProcurementCentreRepository repo) => _centreOverride = repo;
  static void setBookingRepository(BookingRepository repo) => _bookingOverride = repo;
  static void setQueueRepository(QueueRepository repo) => _queueOverride = repo;
  static void setProcurementRepository(ProcurementRepository repo) => _procurementOverride = repo;
  static void setPaymentRepository(PaymentRepository repo) => _paymentOverride = repo;
  static void setNotificationRepository(NotificationRepository repo) => _notificationOverride = repo;
  static void setDisputeRepository(DisputeRepository repo) => _disputeOverride = repo;

  /// Gets the active [FarmerRepository].
  static FarmerRepository get farmer =>
      _farmerOverride ?? (SupabaseConfig.shouldUseSupabase ? _supabaseFarmer : _localFarmer);

  /// Gets the active [ProcurementCentreRepository].
  static ProcurementCentreRepository get centre =>
      _centreOverride ?? (SupabaseConfig.shouldUseSupabase ? _supabaseCentre : _localCentre);

  /// Gets the active [BookingRepository].
  static BookingRepository get booking =>
      _bookingOverride ?? (SupabaseConfig.shouldUseSupabase ? _supabaseBooking : _localBooking);

  /// Gets the active [QueueRepository].
  static QueueRepository get queue =>
      _queueOverride ?? (SupabaseConfig.shouldUseSupabase ? _supabaseQueue : _localQueue);

  /// Gets the active [ProcurementRepository].
  static ProcurementRepository get procurement =>
      _procurementOverride ?? (SupabaseConfig.shouldUseSupabase ? _supabaseProcurement : _localProcurement);

  /// Gets the active [PaymentRepository].
  static PaymentRepository get payment =>
      _paymentOverride ?? (SupabaseConfig.shouldUseSupabase ? _supabasePayment : _localPayment);

  /// Gets the active [NotificationRepository].
  static NotificationRepository get notification =>
      _notificationOverride ?? (SupabaseConfig.shouldUseSupabase ? _supabaseNotification : _localNotification);

  /// Gets the active [DisputeRepository].
  static DisputeRepository get dispute =>
      _disputeOverride ?? (SupabaseConfig.shouldUseSupabase ? _supabaseDispute : _localDispute);
}
