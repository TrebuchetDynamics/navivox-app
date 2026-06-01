import 'package:flutter/material.dart';

import '../config_wire_fields.dart';
import '../model/config_form_model.dart';

class ConfigFieldPresentation {
  ConfigFieldPresentation._({
    required ConfigFormRow row,
    required List<String> validationMessages,
  }) : _row = row,
       validationMessages = List.unmodifiable(validationMessages);

  factory ConfigFieldPresentation.fromRow(
    ConfigFormRow row, {
    List<String> validationMessages = const [],
  }) {
    return ConfigFieldPresentation._(
      row: row,
      validationMessages: validationMessages,
    );
  }

  final ConfigFormRow _row;

  final List<String> validationMessages;

  String get path => _row.field;

  String get label => _row.label;

  String get displayValue => _row.displayValue;

  List<String> get helperLines {
    return [
      if (_row.allowedValues.isNotEmpty)
        'Allowed: ${_row.allowedValues.join(', ')}',
      if (_row.actions.isNotEmpty) 'Actions: ${_row.actions.join(', ')}',
      if (_row.reloadMode.isNotEmpty) 'Reload: ${_row.reloadMode}',
    ];
  }

  String get editInitialValue => _row.editInitialValue;

  ValueKey<String> get editKey => ValueKey('config-edit-$path');

  ValueKey<String> get inputKey => ValueKey('config-input-$path');

  ValueKey<String> get saveKey => ValueKey('config-save-$path');

  bool get obscureText => _row.isSecret;

  TextInputType get keyboardType => configFieldKeyboardTypeFor(_row.type);

  Object? coerceEditValue(String raw) => _row.coerceEditValue(raw);

  bool clearsDraftFor(Object? value) {
    return _row.isSecret && configWireString(value) == null;
  }
}

TextInputType configFieldKeyboardTypeFor(ConfigFormFieldType type) {
  return switch (type) {
    ConfigFormFieldType.number => const TextInputType.numberWithOptions(
      decimal: true,
    ),
    ConfigFormFieldType.integer => const TextInputType.numberWithOptions(
      decimal: false,
    ),
    ConfigFormFieldType.boolean ||
    ConfigFormFieldType.string ||
    ConfigFormFieldType.secret => TextInputType.text,
  };
}
