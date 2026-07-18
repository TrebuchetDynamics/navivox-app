import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../channel/hermes_detached_run_store.dart';

/// Persists only opaque run/session handles needed to reconcile work after the
/// Wing process is recreated. No prompt, output, credential, or transcript is
/// stored here; Hermes Agent remains authoritative for lifecycle and history.
class SecureHermesDetachedRunStore implements HermesDetachedRunStore {
  SecureHermesDetachedRunStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _storageKey = 'wing.hermes.detached_runs.v1';
  static const _maximumLeases = 16;

  final FlutterSecureStorage _secureStorage;

  @override
  Future<List<HermesDetachedRunLease>> load() async {
    final String? encoded;
    try {
      encoded = await _secureStorage.read(key: _storageKey);
    } catch (_) {
      return const [];
    }
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List<Object?>) return const [];
      final leases = <HermesDetachedRunLease>[];
      for (final row in decoded.take(_maximumLeases)) {
        if (row is! Map) continue;
        try {
          leases.add(
            HermesDetachedRunLease.fromJson(
              row.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        } on FormatException {
          // Ignore one malformed lease without discarding valid handles.
        }
      }
      return leases;
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    final bounded = leases.take(_maximumLeases).map((lease) => lease.toJson());
    await _secureStorage.write(
      key: _storageKey,
      value: jsonEncode(bounded.toList()),
    );
  }
}
