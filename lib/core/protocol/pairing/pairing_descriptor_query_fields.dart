import '../serialization/navivox_json.dart';
import 'pairing_descriptor_query_pair.dart';

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
  }) : _orderedPairs = pairingDescriptorOrderedQueryPairs(
         rawQuery: rawQuery,
         queryParametersAll: queryParametersAll,
       );

  final String descriptor;
  final List<PairingDescriptorQueryPair> _orderedPairs;

  String required(String name) {
    final value = optional(name);
    if (value == null) {
      throw FormatException('Pairing descriptor missing $name', descriptor);
    }
    return value;
  }

  String? optional(String name) {
    return _pairingDescriptorFirstScalarQueryValue(_orderedPairs, name);
  }

  bool boolean(String name) {
    return navivoxStrictBoolFromJson(optional(name));
  }

  List<String> csv(String name) {
    final normalizedName = navivoxCanonicalWireFieldName(name);
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

String? _pairingDescriptorFirstScalarQueryValue(
  Iterable<PairingDescriptorQueryPair> pairs,
  String name,
) {
  final normalizedName = navivoxCanonicalWireFieldName(name);
  for (final pair in pairs) {
    if (pair.normalizedName != normalizedName) continue;
    final value = navivoxOptionalStringFromJson(pair.value);
    if (value != null) return value;
  }
  return null;
}
