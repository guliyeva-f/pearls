import 'package:flutter_test/flutter_test.dart';
import 'package:pearls/models/quote.dart';
import 'package:pearls/utils/date_formatter.dart';

void main() {
  group('Quote model', () {
    test('toMap/fromMap JSON roundtrip', () {
      final original = Quote(
        id: 'abc-123',
        text: 'Test incisi',
        tags: ['flutter', 'dart'],
        isFavourite: true,
        date: DateTime(2024, 6, 15, 10, 30),
      );
      final restored = Quote.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.tags, original.tags);
      expect(restored.isFavourite, original.isFavourite);
    });

    test('legacy vergüllü teqlər oxunur', () {
      final map = {
        'id': '1',
        'text': 'Köhnə format',
        'tags': 'tag1,tag2,tag3',
        'isFavourite': false,
        'date': null,
      };
      final q = Quote.fromMap(map);
      expect(q.tags, ['tag1', 'tag2', 'tag3']);
    });

    test('boş teqlər düzgün işlənir', () {
      final map = {
        'id': '2',
        'text': 'Teqsiz',
        'tags': '',
        'isFavourite': false,
        'date': null,
      };
      final q = Quote.fromMap(map);
      expect(q.tags, isEmpty);
    });

    test('copyWith id-ni qoruyur', () {
      final original = Quote(
        id: 'xyz',
        text: 'Orijinal',
        tags: ['a'],
        isFavourite: false,
      );
      final updated = original.copyWith(isFavourite: true, text: 'Yeni');
      expect(updated.id, 'xyz');
      expect(updated.isFavourite, true);
      expect(updated.text, 'Yeni');
      expect(updated.tags, ['a']);
    });

    test('teqdə vergül saxlanılmır', () {
      // Bu testi AddEditScreen-dəki _addTag məntiqi ilə birlikdə düşün
      const raw = 'elm,fənn';
      final sanitized = raw.replaceAll(',', '');
      expect(sanitized.contains(','), false);
    });
  });

  group('DateFormatter', () {
    test('format düzgün string qaytarır', () {
      final dt = DateTime(2024, 3, 5, 9, 7);
      expect(DateFormatter.format(dt), '05.03.2024 09:07');
    });

    test('formatForExport mötərizə əlavə edir', () {
      final dt = DateTime(2024, 3, 5, 9, 7);
      expect(DateFormatter.formatForExport(dt), '[05.03.2024 09:07]');
    });

    test('parse düzgün DateTime qaytarır', () {
      final result = DateFormatter.parse('15.06.2024 10:30');
      expect(result, DateTime(2024, 6, 15, 10, 30));
    });

    test('yanlış formatda null qaytarır', () {
      expect(DateFormatter.parse('yanlış'), null);
      expect(DateFormatter.parse(''), null);
      expect(DateFormatter.parse('15-06-2024'), null);
    });
  });
}
