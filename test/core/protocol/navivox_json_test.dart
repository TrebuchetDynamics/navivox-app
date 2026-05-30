import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_json.dart';

void main() {
  test('strict bool parser accepts only bool values and true/false tokens', () {
    expect(navivoxStrictBoolFromJson(true), isTrue);
    expect(navivoxStrictBoolFromJson(false), isFalse);
    expect(navivoxStrictBoolFromJson(' true '), isTrue);
    expect(navivoxStrictBoolFromJson('FALSE'), isFalse);

    expect(navivoxStrictBoolFromJson('1'), isFalse);
    expect(navivoxStrictBoolFromJson('yes'), isFalse);
    expect(navivoxStrictBoolFromJson(null, fallback: true), isTrue);
  });
}
