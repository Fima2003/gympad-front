/// Utility class for handling HTTP ETags according to RFC 7232
///
/// Handles both strong and weak ETags, with proper validation and parsing.
/// Weak ETags (W/"...") are only appropriate for certain operations.
class ETagUtils {
  /// Regex to validate ETag format
  /// Matches: "abc123" or W/"abc123"
  static final RegExp _etagRegex = RegExp(r'^(?:W/)?"[^"]*"$');

  /// Check if an ETag string is valid according to RFC 7232
  static bool isValid(String? etag) {
    if (etag == null || etag.isEmpty) return false;
    return _etagRegex.hasMatch(etag);
  }

  /// Check if an ETag is weak (starts with W/)
  static bool isWeak(String? etag) {
    return etag != null && etag.startsWith('W/');
  }

  /// Check if an ETag is strong (not weak) and valid
  static bool isStrong(String? etag) {
    return isValid(etag) && !isWeak(etag);
  }

  /// Extract the quoted value from an ETag
  /// Example: W/"abc123" or "abc123" → "abc123"
  static String? extractValue(String? etag) {
    if (!isValid(etag)) return null;
    if (etag == null) return null;

    // Remove W/ prefix if present, then extract quoted string
    String cleaned = etag.startsWith('W/') ? etag.substring(2) : etag;
    return cleaned.replaceAll('"', '');
  }

  /// Get ETag suitable for If-None-Match (GET requests)
  /// Accepts both weak and strong ETags
  /// Used for conditional GET with caching
  static String? getIfNoneMatchHeader(String? etag) {
    if (!isValid(etag)) {
      return null; // Invalid ETag, don't use it
    }
    return etag; // Both weak and strong are OK for If-None-Match
  }

  /// Get ETag suitable for If-Match (PUT/DELETE requests)
  /// Only accepts STRONG ETags (rejects weak ETags)
  /// Used for optimistic concurrency control
  static String? getIfMatchHeader(String? etag) {
    if (!isValid(etag)) {
      return null; // Invalid ETag, don't use it
    }
    if (isWeak(etag)) {
      return null; // Weak ETags cannot be used for If-Match
    }
    return etag; // Only strong ETags are OK for If-Match
  }

  /// Normalize an ETag by ensuring it follows proper format
  /// Returns null if ETag is invalid or weak (for safety)
  static String? normalizeForStorage(String? etag) {
    if (!isValid(etag)) {
      return null;
    }
    // Store only strong ETags; reject weak ones
    if (isWeak(etag)) {
      return null;
    }
    return etag;
  }

  /// Format validation error message for logging
  static String getValidationErrorMessage(String? etag) {
    if (etag == null) return 'ETag is null';
    if (etag.isEmpty) return 'ETag is empty';
    if (isWeak(etag))
      return 'Weak ETag provided (W/"..."): cannot be used for modification requests';
    if (!isValid(etag)) return 'Invalid ETag format: $etag';
    return 'Unknown validation error';
  }
}
