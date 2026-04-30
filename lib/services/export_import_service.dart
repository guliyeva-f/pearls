import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/quote.dart';
import '../utils/date_formatter.dart';

class ExportImportService {
  static const _uuid = Uuid();

  Future<void> exportQuotes(List<Quote> quotes) async {
    final buffer = StringBuffer();
    final ordered = quotes.reversed.toList();
    for (final quote in ordered) {
      final date = quote.date ?? DateTime.now();
      buffer.writeln(DateFormatter.formatForExport(date));
      buffer.writeln(quote.text);
      buffer.writeln();
      if (quote.tags.isNotEmpty) {
        buffer.writeln(quote.tags.map((t) => '#$t').join(' '));
      }
      buffer.writeln();
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pearls_backup.txt');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)]);

    try {
      await file.delete();
    } catch (_) {}
  }

  Future<List<Quote>> importQuotes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result == null) return [];
    final path = result.files.single.path;
    if (path == null) return [];
    final content = await File(path).readAsString();
    return _parseTxt(content);
  }

  List<Quote> _parseTxt(String content) {
    final quotes = <Quote>[];
    final datePattern = RegExp(r'\[(\d{2}\.\d{2}\.\d{4} \d{2}:\d{2})\]');
    final matches = datePattern.allMatches(content).toList();
    if (matches.isEmpty) return [];

    for (int i = 0; i < matches.length; i++) {
      final dateStr = matches[i].group(1)!;
      final start = matches[i].end;
      final end = i + 1 < matches.length
          ? matches[i + 1].start
          : content.length;
      final block = content.substring(start, end).trim();
      if (block.isEmpty) continue;

      final lines = block.split('\n').map((l) => l.trim()).toList();
      final tagLineIndex = lines.indexWhere((l) => l.startsWith('#'));

      String text;
      List<String> tags = [];

      if (tagLineIndex == -1) {
        text = lines.where((l) => l.isNotEmpty).join('\n');
      } else {
        text = lines.sublist(0, tagLineIndex).join('\n').trim();
        final tagLine = lines[tagLineIndex];
        tags = tagLine
            .split(' ')
            .where((t) => t.startsWith('#') && t.length > 1)
            .map((t) => t.substring(1).replaceAll(',', ''))
            .toList();
      }

      if (text.isEmpty) continue;

      quotes.add(
        Quote(
          id: _uuid.v4(),
          text: text,
          tags: tags,
          date: DateFormatter.parse(dateStr),
        ),
      );
    }

    return quotes;
  }
}
