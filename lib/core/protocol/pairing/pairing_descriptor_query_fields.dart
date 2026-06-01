import '../serialization/navivox_json.dart';

/// Query-field access for the `navivox://connect` pairing descriptor.
///
/// This keeps two descriptor contracts visible in one place:
/// - scalar fields accept snake_case/camelCase aliases and use the first
///   non-blank value for each concrete query key;
/// - list-like fields preserve the producer's original query-parameter order,
///   even when aliases are interleaved.
class PairingDescriptorQueryFields {
  PairingDescriptorQueryFields({
    required this.descriptor,
    required Map<String, List<String>> queryParametersAll,
    required String rawQuery,
  }) : _firstValues = navivoxFirstNonBlankQueryParameterValues(
         queryParametersAll,
       ),
       _orderedPairs = _orderedQueryPairs(rawQuery);

  final String descriptor;
  final Map<String, String> _firstValues;
  final List<_PairingDescriptorQueryPair> _orderedPairs;

  String required(String name) {
    final value = optional(name);
    if (value == null) {
      throw FormatException('Pairing descriptor missing $name', descriptor);
    }
    return value;
  }

  String? optional(String name) {
    return navivoxFirstStringFieldFromJson(_firstValues, [name]);
  }

  bool boolean(String name) {
    return navivoxStrictBoolFromJson(optional(name));
  }

  List<String> csv(String name) {
    final normalizedName = normalizePairingDescriptorFieldName(name);
    return _orderedPairs
        .where((pair) => pair.normalizedName == normalizedName)
        .map((pair) => navivoxOptionalStringFromJson(pair.value))
        .whereType<String>()
        .expand((value) => value.split(','))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

String normalizePairingDescriptorFieldName(String value) =>
    value.toLowerCase().replaceAll('_', '');

List<_PairingDescriptorQueryPair> _orderedQueryPairs(String rawQuery) {
  if (rawQuery.isEmpty) return const [];
  return rawQuery
      .split('&')
      .map(_PairingDescriptorQueryPair.parse)
      .toList(growable: false);
}

class _PairingDescriptorQueryPair {
  const _PairingDescriptorQueryPair({
    required this.normalizedName,
    required this.value,
  });

  factory _PairingDescriptorQueryPair.parse(String component) {
    final separator = component.indexOf('=');
    final rawName = separator == -1
        ? component
        : component.substring(0, separator);
    final rawValue = separator == -1 ? '' : component.substring(separator + 1);
    return _PairingDescriptorQueryPair(
      normalizedName: normalizePairingDescriptorFieldName(
        Uri.decodeQueryComponent(rawName),
      ),
      value: Uri.decodeQueryComponent(rawValue),
    );
  }

  final String normalizedName;
  final String value;
}
