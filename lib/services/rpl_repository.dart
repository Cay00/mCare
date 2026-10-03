import 'dart:convert';
import 'package:archive/archive.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/medication.dart';
import 'gtin.dart';

class AmbiguousMedicationException implements Exception {}

/// The compressed official RPL snapshot is loaded once, off the UI isolate.
/// Updating it is reproducible with tool/update_rpl.dart; no website scraping.
class RplRepository {
  RplRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<Map<String, dynamic>>? _index;

  Future<Map<String, dynamic>> _load() async {
    try {
      final bytes = await _bundle.load('assets/data/rpl_packages.json.gz');
      return await compute(
        _decodeIndex,
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } catch (_) {
      _index = null; // Allow a later retry after a loading failure.
      rethrow;
    }
  }

  Future<MedicationProduct?> findByBarcode(String code) async {
    final gtin = gtinFromBarcode(code);
    if (gtin == null) throw const FormatException('Invalid EAN/GTIN');
    final index = await (_index ??= _load());
    if ((index['ambiguousGtins'] as List).contains(gtin)) {
      throw AmbiguousMedicationException();
    }
    final record = (index['packages'] as Map<String, dynamic>)[gtin];
    if (record == null) return null;
    return MedicationProduct.fromJson(record as Map<String, dynamic>);
  }

  Future<List<MedicationProduct>> prescriptionProducts() async {
    final index = await (_index ??= _load());
    return (index['packages'] as Map<String, dynamic>).values
        .map(
          (record) =>
              MedicationProduct.fromJson(record as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}

Map<String, dynamic> _decodeIndex(Uint8List bytes) {
  final index =
      jsonDecode(utf8.decode(GZipDecoder().decodeBytes(bytes)))
          as Map<String, dynamic>;
  if (index['schemaVersion'] != 1 ||
      index['packages'] is! Map ||
      index['ambiguousGtins'] is! List) {
    throw const FormatException('Invalid RPL index');
  }
  return index;
}
