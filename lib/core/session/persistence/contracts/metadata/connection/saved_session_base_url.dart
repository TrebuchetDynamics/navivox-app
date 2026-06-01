import '../../../../../protocol/navivox_endpoint_uri.dart';
import '../../../../../protocol/navivox_json.dart';

import 'session_uri_text_shape.dart';

/// Reconnect-safe projection for saved HTTP base URL metadata.
///
/// Setup/pairing URLs can include bootstrap-only query parameters, so valid
/// endpoint URLs are reduced to their HTTP origin. URL-shaped values that fail
/// endpoint parsing are rejected instead of being kept as legacy text because
/// they can still carry secrets in query strings or fragments.
class SavedSessionBaseUrlMetadata {
  const SavedSessionBaseUrlMetadata._({
    required this.durableBaseUrl,
    required this.isLegacyText,
    required this.isRejectedUrl,
  });

  factory SavedSessionBaseUrlMetadata.fromStoredValue(Object? value) {
    final text = navivoxOptionalStringFromJson(value);
    if (text == null) return const SavedSessionBaseUrlMetadata.absent();

    final baseUrl = _httpBaseUrlFromEndpointText(text);
    if (baseUrl != null) {
      return SavedSessionBaseUrlMetadata.durableEndpoint(baseUrl);
    }

    if (_looksLikeEndpointUrl(text)) {
      return const SavedSessionBaseUrlMetadata.rejectedUrl();
    }

    return SavedSessionBaseUrlMetadata.legacyText(text);
  }

  const SavedSessionBaseUrlMetadata.absent()
    : this._(durableBaseUrl: null, isLegacyText: false, isRejectedUrl: false);

  const SavedSessionBaseUrlMetadata.durableEndpoint(String value)
    : this._(durableBaseUrl: value, isLegacyText: false, isRejectedUrl: false);

  const SavedSessionBaseUrlMetadata.legacyText(String value)
    : this._(durableBaseUrl: value, isLegacyText: true, isRejectedUrl: false);

  const SavedSessionBaseUrlMetadata.rejectedUrl()
    : this._(durableBaseUrl: null, isLegacyText: false, isRejectedUrl: true);

  final String? durableBaseUrl;
  final bool isLegacyText;
  final bool isRejectedUrl;

  bool get isAbsent => durableBaseUrl == null && !isRejectedUrl;
}

String? durableSavedSessionBaseUrlFromMetadata(Object? value) {
  return SavedSessionBaseUrlMetadata.fromStoredValue(value).durableBaseUrl;
}

String? _httpBaseUrlFromEndpointText(String value) {
  try {
    return navivoxHttpBaseUrlFromEndpointString(value);
  } on FormatException {
    return null;
  }
}

bool _looksLikeEndpointUrl(String value) {
  return classifySavedSessionUriTextShape(value).isExplicitUriScheme;
}
