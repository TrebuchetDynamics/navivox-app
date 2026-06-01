import '../serialization/navivox_json.dart';

/// One decoded query pair from a `navivox://connect` pairing descriptor.
///
/// Pairing descriptors need ordered, alias-aware query access because repeated
/// scalar aliases choose the first non-blank candidate while list-like fields
/// preserve producer order across snake_case/camelCase aliases.
class PairingDescriptorQueryPair {
  const PairingDescriptorQueryPair({
    required this.normalizedName,
    required this.value,
  });

  factory PairingDescriptorQueryPair.parse(String component) {
    final parts = pairingDescriptorRawQueryPairParts(component);
    return PairingDescriptorQueryPair(
      normalizedName: navivoxCanonicalWireFieldName(
        pairingDescriptorDecodeQueryPart(parts.name, component),
      ),
      value: pairingDescriptorDecodeQueryPart(parts.value, component),
    );
  }

  final String normalizedName;
  final String value;
}

class PairingDescriptorRawQueryPairParts {
  const PairingDescriptorRawQueryPairParts({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;
}

PairingDescriptorRawQueryPairParts pairingDescriptorRawQueryPairParts(
  String component,
) {
  final separator = component.indexOf('=');
  return PairingDescriptorRawQueryPairParts(
    name: separator == -1 ? component : component.substring(0, separator),
    value: separator == -1 ? '' : component.substring(separator + 1),
  );
}

String pairingDescriptorDecodeQueryPart(String value, String sourceComponent) {
  try {
    return Uri.decodeQueryComponent(value);
  } on ArgumentError {
    throw FormatException(
      'Pairing descriptor query contains invalid percent encoding',
      sourceComponent,
    );
  }
}

List<PairingDescriptorQueryPair> pairingDescriptorOrderedQueryPairs({
  required String rawQuery,
  required Map<String, List<String>> queryParametersAll,
}) {
  if (rawQuery.isNotEmpty) {
    return rawQuery
        .split('&')
        .map(PairingDescriptorQueryPair.parse)
        .toList(growable: false);
  }

  return queryParametersAll.entries
      .expand(
        (entry) => entry.value.map(
          (value) => PairingDescriptorQueryPair(
            normalizedName: navivoxCanonicalWireFieldName(entry.key),
            value: value,
          ),
        ),
      )
      .toList(growable: false);
}
