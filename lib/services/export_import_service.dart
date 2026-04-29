import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';

class ExportImportService {
  Future<void> exportQuotes(List<Quote> quotes) async {
    final buffer = StringBuffer();
    for (final quote in quotes) {
      buffer.writeln('@');
      buffer.writeln(quote.text);
      buffer.writeln();
      buffer.writeln(quote.tags.map((t) => '#$t').join(' '));
      buffer.writeln();
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pearls_backup.txt');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<List<Quote>> importQuotes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result == null) return [];

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    return _parseTxt(content);
  }

  List<Quote> _parseTxt(String content) {
    final quotes = <Quote>[];
    final blocks = content.split('@');

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      final lines = trimmed.split('\n');
      final tagLineIndex = lines.indexWhere((l) => l.trim().startsWith('#'));

      String text;
      List<String> tags = [];

      if (tagLineIndex == -1) {
        text = lines.join('\n').trim();
      } else {
        text = lines.sublist(0, tagLineIndex).join('\n').trim();
        final tagLine = lines[tagLineIndex].trim();
        tags = tagLine
            .split(' ')
            .where((t) => t.startsWith('#') && t.length > 1)
            .map((t) => t.substring(1))
            .toList();
      }

      if (text.isEmpty) continue;

      quotes.add(Quote(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            quotes.length.toString(),
        text: text,
        tags: tags,
      ));
    }

    return quotes;
  }
}