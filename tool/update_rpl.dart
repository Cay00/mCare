// Run from the repository root: dart run tool/update_rpl.dart [local XML path]
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'package:m_opiekun/services/rpl_xml.dart';

Future<void> main(List<String> arguments) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  Directory? temporary;
  try {
    late File source;
    if (arguments.isNotEmpty) {
      source = File(arguments.single);
    } else {
      temporary = await Directory.systemTemp.createTemp('mcare-rpl-');
      source = File('${temporary.path}/overall.xml');
      stdout.writeln('Downloading official RPL XML...');
      final request = await client.getUrl(Uri.parse(rplReportUrl));
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('RPL HTTP ${response.statusCode}');
      }
      await response
          .timeout(const Duration(seconds: 60))
          .pipe(source.openWrite());
    }
    final document = XmlDocument.parse(await source.readAsString());
    final root = document.rootElement;
    if (root.name.local != 'produktyLecznicze' ||
        root.namespaceUri != rplNamespace ||
        root.getAttribute('stanNaDzien') == null) {
      throw const FormatException('Unexpected RPL schema');
    }
    final packages = <String, Map<String, dynamic>>{};
    final ambiguous = <String>{};
    for (final node in root.childElements) {
      if (node.name.local != 'produktLeczniczy') continue;
      for (final product in productsFromRpl(node)) {
        final gtin = product.gtin!;
        if (ambiguous.contains(gtin)) continue;
        final record = product.toJson();
        final previous = packages[gtin];
        if (previous != null && jsonEncode(previous) != jsonEncode(record)) {
          packages.remove(gtin);
          ambiguous.add(gtin);
        } else {
          packages[gtin] = record;
        }
      }
    }
    if (packages.isEmpty) {
      throw const FormatException('RPL contains no packages');
    }
    final sorted = Map.fromEntries(
      packages.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final result = {
      'schemaVersion': 1,
      'source': rplReportUrl,
      'asOf': root.getAttribute('stanNaDzien'),
      'ambiguousGtins': ambiguous.toList()..sort(),
      'packages': sorted,
    };
    final output = File('assets/data/rpl_packages.json.gz');
    await output.parent.create(recursive: true);
    // Only replace the asset after the complete XML has been validated.
    await output.writeAsBytes(gzip.encode(utf8.encode(jsonEncode(result))));
    stdout.writeln(
      '${packages.length} packages, ${ambiguous.length} ambiguous; '
      'RPL ${result['asOf']}; ${await output.length()} bytes.',
    );
    stdout.writeln('Acard sample: ${packages['05909990672516']}');
  } finally {
    client.close(force: true);
    if (temporary != null) await temporary.delete(recursive: true);
  }
}
