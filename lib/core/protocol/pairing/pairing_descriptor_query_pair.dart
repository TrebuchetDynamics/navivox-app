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
    final separator = component.indexOf('=');
    final rawName = separator == -1
        ? component
        : component.substring(0, separator);
    final rawValue = separator == -1 ? '' : component.substring(separator + 1);
    return PairingDescriptorQueryPair(
      normalizedName: navivoxCanonicalWireFieldName(
        Uri.decodeQueryComponent(rawName),
      ),
      value: Uri.decodeQueryComponent(rawValue),
    );
  }

  final String normalizedName;
  final String value;
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
