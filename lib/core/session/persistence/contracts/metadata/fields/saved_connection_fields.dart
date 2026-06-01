import '../../../../shared/session_text.dart';

import '../connection/session_connection_metadata.dart';

class SavedConnectionFields {
  const SavedConnectionFields({
    required this.baseUrl,
    this.webSocketUrl,
    this.gatewayId,
  });

  factory SavedConnectionFields.fromInput({
    required String baseUrl,
    String? webSocketUrl,
    String? gatewayId,
  }) {
    final metadata = SessionConnectionMetadata.fromStoredValues(
      baseUrl: requiredSessionText(baseUrl, fieldName: 'baseUrl'),
      webSocketUrl: webSocketUrl,
      gatewayId: gatewayId,
    );

    return SavedConnectionFields(
      baseUrl: metadata.baseUrl,
      webSocketUrl: metadata.webSocketUrl,
      gatewayId: metadata.gatewayId,
    );
  }

  final String baseUrl;
  final String? webSocketUrl;
  final String? gatewayId;
}
