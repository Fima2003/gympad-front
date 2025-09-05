/// Defines feature flags / permissions derived from authentication mode.
/// Keep intentionally small; extend cautiously (additive) to avoid churn.
class Capabilities {
  final bool canUpload; // Can send workouts to backend
  final bool canSync;   // Can perform background sync / migrations

  const Capabilities._({
    required this.canUpload,
    required this.canSync,
  });

  static const Capabilities guest = Capabilities._(
    canUpload: false,
    canSync: false,
  );

  static const Capabilities authenticated = Capabilities._(
    canUpload: true,
    canSync: true,
  );
}

/// Lightweight typedef used by services to query current capabilities without
/// tying themselves to Bloc / Provider specific implementations.
typedef CapabilitiesProvider = Capabilities Function();
