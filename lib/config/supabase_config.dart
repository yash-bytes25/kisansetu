// KisanSetu (SIH26032) - Backend Configuration
// Handles environment variable configuration for local and Supabase modes.
// NEVER hardcode private service-role keys in this or any client-side file.

/// Operating mode for KisanSetu data access.
enum BackendMode {
  /// Local in-memory prototype state (Phase 1-9 default).
  /// Runs fully offline with mock services, demo OTP (123456),
  /// and zero external credentials needed.
  local,

  /// Live Supabase backend mode (Phase 10+).
  /// Uses Supabase Flutter client with publishable/anon key only.
  supabase,
}

/// Lifecycle status definitions for procurement bookings.
class BookingLifecycleStatus {
  BookingLifecycleStatus._();

  static const String booked = 'BOOKED';
  static const String approved = 'APPROVED';
  static const String checkedIn = 'CHECKED_IN';
  static const String waiting = 'WAITING';
  static const String processing = 'PROCESSING';
  static const String completed = 'COMPLETED';
  static const String standby = 'STANDBY';
  static const String cancelled = 'CANCELLED';
  static const String expired = 'EXPIRED';
  static const String noShow = 'NO_SHOW';

  static const List<String> all = [
    booked,
    approved,
    checkedIn,
    waiting,
    processing,
    completed,
    standby,
    cancelled,
    expired,
    noShow,
  ];

  static bool isValid(String status) =>
      all.any((s) => s.toLowerCase() == status.toLowerCase());

  /// Enforces valid booking lifecycle state machine transitions.
  /// Prevents invalid transitions such as reverting from terminal states (COMPLETED, CANCELLED, etc.).
  static bool canTransition(String currentStatus, String targetStatus) {
    final cur = currentStatus.toUpperCase().trim();
    final tgt = targetStatus.toUpperCase().trim();

    if (!isValid(cur) || !isValid(tgt)) return false;
    if (cur == tgt) return true; // Idempotent

    switch (cur) {
      case booked:
        return tgt == approved ||
            tgt == checkedIn ||
            tgt == waiting ||
            tgt == standby ||
            tgt == cancelled ||
            tgt == expired ||
            tgt == noShow;
      case approved:
        return tgt == checkedIn ||
            tgt == waiting ||
            tgt == standby ||
            tgt == cancelled ||
            tgt == expired ||
            tgt == noShow;
      case checkedIn:
        return tgt == waiting ||
            tgt == processing ||
            tgt == standby ||
            tgt == cancelled;
      case waiting:
        return tgt == processing ||
            tgt == standby ||
            tgt == cancelled ||
            tgt == noShow;
      case processing:
        return tgt == completed || tgt == cancelled;
      case standby:
        return tgt == approved ||
            tgt == checkedIn ||
            tgt == waiting ||
            tgt == cancelled ||
            tgt == expired;
      case completed:
      case cancelled:
      case expired:
      case noShow:
        // Terminal states cannot transition back to active operations
        return false;
      default:
        return false;
    }
  }
}

/// Status definitions for transparent MSP payments.
class PaymentLifecycleStatus {
  PaymentLifecycleStatus._();

  static const String notEligible = 'NOT_ELIGIBLE';
  static const String pending = 'PENDING';
  static const String initiated = 'INITIATED';
  static const String processing = 'PROCESSING';
  static const String success = 'SUCCESS';
  static const String failed = 'FAILED';
  static const String reversed = 'REVERSED';

  static const List<String> all = [
    notEligible,
    pending,
    initiated,
    processing,
    success,
    failed,
    reversed,
  ];

  static bool isValid(String status) =>
      all.any((s) => s.toLowerCase() == status.toLowerCase());

  /// Enforces transparent MSP payment lifecycle transitions.
  static bool canTransition(String currentStatus, String targetStatus) {
    final cur = currentStatus.toUpperCase().trim();
    final tgt = targetStatus.toUpperCase().trim();

    if (!isValid(cur) || !isValid(tgt)) return false;
    if (cur == tgt) return true; // Idempotent

    switch (cur) {
      case notEligible:
        return tgt == pending;
      case pending:
        return tgt == initiated || tgt == processing || tgt == notEligible || tgt == failed;
      case initiated:
        return tgt == processing || tgt == failed;
      case processing:
        return tgt == success || tgt == failed;
      case failed:
        return tgt == initiated || tgt == processing || tgt == pending;
      case success:
        return tgt == reversed;
      case reversed:
        // Terminal state
        return false;
      default:
        return false;
    }
  }
}

/// Central configuration for Supabase integration and backend mode selection.
class SupabaseConfig {
  SupabaseConfig._();

  /// Default placeholder URL if not supplied via --dart-define.
  static const String placeholderUrl = 'https://placeholder-project.supabase.co';

  /// Default placeholder publishable/anon key if not supplied via --dart-define.
  static const String placeholderAnonKey = 'placeholder-publishable-anon-key';

  /// Supabase project URL passed at compile/run time via:
  /// `--dart-define=SUPABASE_URL=https://<your-project-id>.supabase.co`
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: placeholderUrl,
  );

  /// Supabase publishable/anon client key passed at compile/run time via:
  /// `--dart-define=SUPABASE_PUBLISHABLE_KEY=<your-anon-key>`
  ///
  /// IMPORTANT: ONLY publishable/anon keys may be provided here.
  /// NEVER provide or commit a service-role key.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: placeholderAnonKey,
  );

  static BackendMode? _modeOverride;

  /// Allows programmatic overriding for unit/widget testing.
  static void setModeOverride(BackendMode? mode) {
    _modeOverride = mode;
  }

  /// Target backend mode passed at compile/run time via:
  /// `--dart-define=BACKEND_MODE=supabase` (or `local`).
  ///
  /// Defaults to [BackendMode.local] so that the demo continues
  /// working without any external credentials.
  static BackendMode get backendMode {
    if (_modeOverride != null) return _modeOverride!;
    const String modeStr = String.fromEnvironment(
      'BACKEND_MODE',
      defaultValue: 'local',
    );
    if (modeStr.toLowerCase() == 'supabase') {
      return BackendMode.supabase;
    }
    return BackendMode.local;
  }

  /// Whether Supabase credentials have been provided and differ from placeholders.
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl != placeholderUrl &&
        supabasePublishableKey.isNotEmpty &&
        supabasePublishableKey != placeholderAnonKey;
  }

  /// Returns true if the app is explicitly instructed to use Supabase AND
  /// valid credentials are present (or override is explicitly active).
  static bool get shouldUseSupabase {
    if (_modeOverride == BackendMode.supabase) return true;
    if (_modeOverride == BackendMode.local) return false;
    return backendMode == BackendMode.supabase && isConfigured;
  }
}
