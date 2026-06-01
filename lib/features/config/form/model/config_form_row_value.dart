/// Value-shape helpers for config form rows.
///
/// The gateway normally passes config values directly, while some compatibility
/// payloads wrap scalar values in a small metadata envelope. Keep that unwrap
/// rule narrow so structured config objects that happen to have a `value` field
/// are not truncated before display, edit, or draft comparison.
Object? configFormPlainRowValue(Object? rawValue) {
  if (_isConfigFormValueEnvelope(rawValue)) {
    return (rawValue as Map)['value'];
  }
  return rawValue;
}

const _configFormValueEnvelopeKeys = {
  'value',
  'source',
  'secret_status',
  'secretStatus',
};

bool _isConfigFormValueEnvelope(Object? rawValue) {
  if (rawValue is! Map || !rawValue.containsKey('value')) return false;
  return rawValue.keys.every(_configFormValueEnvelopeKeys.contains);
}
