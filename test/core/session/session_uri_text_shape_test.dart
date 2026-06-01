import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/saved_session_base_url.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/saved_session_web_socket_endpoint.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/session_uri_text_shape.dart';

void main() {
  group('saved session URI text syntax', () {
    test('exposes bracketed host literals before URI parser scheme checks', () {
      final syntax = SavedSessionUriTextSyntax.parse('[::1]:8765/stream');

      expect(syntax.text, '[::1]:8765/stream');
      expect(syntax.startsWithBracketedHostLiteral, isTrue);
      expect(syntax.hasAuthoritySchemeSeparator, isFalse);
      expect(syntax.hasPortLikeSchemeSeparator, isFalse);
      expect(syntax.hasNonPortSchemeSeparator, isTrue);
    });

    test('does not let bracketed host compatibility hide authority URLs', () {
      final syntax = SavedSessionUriTextSyntax.parse(
        '[::1]://stream?token=secret',
      );

      expect(syntax.startsWithBracketedHostLiteral, isFalse);
      expect(syntax.hasAuthoritySchemeSeparator, isTrue);
    });

    test('exposes host-port versus named scheme separators', () {
      expect(
        SavedSessionUriTextSyntax.parse(
          'gateway.example:8765/stream',
        ).hasPortLikeSchemeSeparator,
        isTrue,
      );
      expect(
        SavedSessionUriTextSyntax.parse(
          'mailto:secret-token',
        ).hasNonPortSchemeSeparator,
        isTrue,
      );
    });

    test('exposes URI state delimiters in legacy-shaped metadata', () {
      final query = SavedSessionUriTextSyntax.parse(
        'gateway.example:8765/stream?token=secret',
      );
      final fragment = SavedSessionUriTextSyntax.parse(
        'gateway.example:8765/stream#handoff',
      );
      final userInfo = SavedSessionUriTextSyntax.parse(
        'pairing-token@gateway.example:8765/stream',
      );
      final combined = SavedSessionUriTextSyntax.parse(
        'pairing-token@gateway.example:8765/stream?token=secret#handoff',
      );
      final safe = SavedSessionUriTextSyntax.parse(
        'gateway.example:8765/stream',
      );

      expect(query.unsafeLegacyDelimiters, [
        SavedSessionUriTextUnsafeDelimiter.query,
      ]);
      expect(fragment.unsafeLegacyDelimiters, [
        SavedSessionUriTextUnsafeDelimiter.fragment,
      ]);
      expect(userInfo.unsafeLegacyDelimiters, [
        SavedSessionUriTextUnsafeDelimiter.userInfo,
      ]);
      expect(combined.unsafeLegacyDelimiters, [
        SavedSessionUriTextUnsafeDelimiter.query,
        SavedSessionUriTextUnsafeDelimiter.fragment,
        SavedSessionUriTextUnsafeDelimiter.userInfo,
      ]);
      expect(query.hasNonDurableUriStateDelimiter, isTrue);
      expect(fragment.hasNonDurableUriStateDelimiter, isTrue);
      expect(userInfo.hasNonDurableUriStateDelimiter, isTrue);
      expect(safe.hasNonDurableUriStateDelimiter, isFalse);
      expect(safe.unsafeLegacyDelimiters, isEmpty);
    });
  });

  group('saved session URI text classification', () {
    test(
      'keeps explicit URL, named scheme, and legacy host shapes distinct',
      () {
        expect(
          classifySavedSessionUriTextShape('wss://gateway.example/stream'),
          SavedSessionUriTextShape.authorityUrl,
        );
        expect(
          classifySavedSessionUriTextShape('mailto:secret-token'),
          SavedSessionUriTextShape.namedScheme,
        );
        expect(
          classifySavedSessionUriTextShape('gateway.example:8765/stream'),
          SavedSessionUriTextShape.hostPortLike,
        );
        expect(
          classifySavedSessionUriTextShape('[::1]:8765/stream'),
          SavedSessionUriTextShape.bracketedHostLiteral,
        );
        expect(
          classifySavedSessionUriTextShape('[::1]://stream?token=secret'),
          SavedSessionUriTextShape.authorityUrl,
        );
      },
    );

    test('exposes the shared unsafe legacy-preservation decision', () {
      final safeLegacy = SavedSessionUriTextFacts.fromText(
        'gateway.example:8765/stream',
      );
      expect(safeLegacy.shape, SavedSessionUriTextShape.hostPortLike);
      expect(safeLegacy.isUnsafeToPreserveAsLegacy, isFalse);

      final legacyWithTokenDelimiter = SavedSessionUriTextFacts.fromText(
        'gateway.example:8765/stream?pairing_token=secret',
      );
      expect(
        legacyWithTokenDelimiter.shape,
        SavedSessionUriTextShape.hostPortLike,
      );
      expect(legacyWithTokenDelimiter.isUnsafeToPreserveAsLegacy, isTrue);

      final malformedUrl = SavedSessionUriTextFacts.fromText(
        'wss://gateway.example:bad/stream',
      );
      expect(malformedUrl.shape, SavedSessionUriTextShape.authorityUrl);
      expect(malformedUrl.isUnsafeToPreserveAsLegacy, isTrue);
    });

    test(
      'base-url and websocket projections share unsafe legacy filtering',
      () {
        const legacyWithTokenDelimiter =
            'gateway.example:8765/stream?pairing_token=secret';

        expect(
          durableSavedSessionBaseUrlFromMetadata(legacyWithTokenDelimiter),
          isNull,
        );
        expect(
          durableSavedSessionWebSocketUrlFromMetadata(legacyWithTokenDelimiter),
          isNull,
        );
      },
    );
  });
}
