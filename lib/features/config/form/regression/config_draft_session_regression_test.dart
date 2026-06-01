import '../draft/config_draft_edit_value.dart';

void main() {
  reEditingAStagedNonSecretDraftUsesTheStagedValue();
}

void reEditingAStagedNonSecretDraftUsesTheStagedValue() {
  final initialValue = configDraftEditInitialValue('new name');

  _expect(
    initialValue == 'new name',
    're-editing a staged draft should show the staged value instead of the persisted value',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
