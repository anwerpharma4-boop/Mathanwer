import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:english_for_iraq/content/book_data.dart';
import 'package:english_for_iraq/content/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pdf = File(bookAsset);

  test('the original textbook PDF is bundled byte-for-byte unchanged', () {
    expect(pdf.existsSync(), isTrue, reason: 'missing $bookAsset');
    final digest = sha256.convert(pdf.readAsBytesSync()).toString();
    expect(digest, bookSha256);
  });

  test('the PDF has exactly 96 pages', () {
    final text = String.fromCharCodes(pdf.readAsBytesSync());
    // Count page objects (/Type /Page but not /Type /Pages).
    final pages = RegExp(r'/Type\s*/Page(?![s\w])').allMatches(text).length;
    expect(pages, 96);
    expect(bookPageCount, 96);
  });

  test('pdfx asset is declared in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/book/'));
  });

  test('every one of the 96 pages is reachable and described', () {
    for (var p = 1; p <= bookPageCount; p++) {
      final d = describePage(p);
      expect(d, isNot('Page $p'), reason: 'page $p is not mapped to any section or lesson');
    }
  });

  test('lesson pages are valid PDF indices and follow the book order', () {
    var last = 7;
    for (final u in units) {
      expect(u.firstPage, greaterThan(last));
      for (final l in u.lessons) {
        for (final p in l.pages) {
          expect(p, inInclusiveRange(u.firstPage, u.lastPage), reason: l.id);
          expect(p, inInclusiveRange(1, bookPageCount));
        }
      }
      // All pages of the unit are covered by a lesson, project or story.
      final covered = {for (final l in u.lessons) ...l.pages};
      for (var p = u.firstPage; p <= u.lastPage; p++) {
        expect(covered, contains(p), reason: 'unit ${u.id} page $p');
      }
      last = u.lastPage;
    }
    expect(units.length, 8);
    expect(units.last.lastPage, 79);
  });

  test('units match the Book map (pages 4-5)', () {
    expect(units.map((u) => u.title).toList(), [
      'Hello',
      'My school',
      'My toys',
      'Revision',
      'At the zoo',
      'My body',
      'My family',
      'Revision',
    ]);
    expect(units.where((u) => u.lessons.any((l) => l.kind == LessonKind.project)).map((u) => u.id), [1, 3, 5, 7]);
    expect(units.where((u) => u.lessons.any((l) => l.kind == LessonKind.story)).map((u) => u.id), [2, 4, 6, 8]);
  });
}
