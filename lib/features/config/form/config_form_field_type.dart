enum ConfigFormFieldType {
  string,
  number,
  integer,
  boolean,
  secret;

  factory ConfigFormFieldType.fromWire(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'number' => ConfigFormFieldType.number,
      'integer' || 'int' => ConfigFormFieldType.integer,
      'boolean' || 'bool' => ConfigFormFieldType.boolean,
      'secret' => ConfigFormFieldType.secret,
      'enum' || 'string_list' => ConfigFormFieldType.string,
      _ => ConfigFormFieldType.string,
    };
  }

  bool get isNumeric =>
      this == ConfigFormFieldType.number || this == ConfigFormFieldType.integer;
}
