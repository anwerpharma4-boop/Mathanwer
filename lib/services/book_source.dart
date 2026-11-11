import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

import '../content/book_data.dart';

/// Renders pages of the original textbook PDF.
///
/// The PDF file is bundled unchanged; this class only rasterises pages for
/// display. All pages of this book are A4 (595.32 x 841.92 pt).
abstract class BookSource {
  int get pageCount;

  /// Height / width of a page.
  double get aspectRatio => 841.92 / 595.32;

  Future<void> open();

  /// Returns encoded image bytes (JPEG) of [page] (1-based) rendered
  /// [widthPx] pixels wide. [isWanted] lets the queue skip requests whose
  /// widget has gone away.
  Future<Uint8List?> render(int page, int widthPx, {bool Function()? isWanted});

  Future<void> close();
}

/// Width tiers so that cached renders can be re-used.
const List<int> renderTiers = [180, 720, 1100, 1600, 2480];

/// 2480 px across an A4 page = 300 dpi, the native resolution of the
/// scanned text layer of this PDF, so zooming further gains nothing.
const int maxRenderWidth = 2480;

int tierFor(double widthPx) {
  for (final t in renderTiers) {
    if (widthPx <= t) return t;
  }
  return maxRenderWidth;
}

class _Job {
  _Job(this.page, this.width, this.isWanted);
  final int page;
  final int width;
  final bool Function()? isWanted;
  final completer = Completer<Uint8List?>();
}

/// pdfx based implementation (Android PdfRenderer). Android allows only one
/// page to be open at a time, so all renders go through a serial queue that
/// serves the most recent request first.
class PdfxBookSource extends BookSource {
  PdfxBookSource({this.asset = bookAsset});

  final String asset;
  PdfDocument? _doc;
  int _pageCount = bookPageCount;
  final List<_Job> _queue = [];
  bool _running = false;

  /// Small LRU caches of encoded bytes. Large renders are memory hungry, so
  /// only a couple are kept.
  final _small = _Lru<String, Uint8List>(140);
  final _large = _Lru<String, Uint8List>(3);

  @override
  int get pageCount => _pageCount;

  @override
  Future<void> open() async {
    if (_doc != null) return;
    _doc = await PdfDocument.openAsset(asset);
    _pageCount = _doc!.pagesCount;
  }

  @override
  Future<Uint8List?> render(int page, int widthPx, {bool Function()? isWanted}) {
    final w = widthPx.clamp(64, maxRenderWidth);
    final key = '$page@$w';
    final cached = (w > 1100 ? _large : _small).get(key);
    if (cached != null) return Future.value(cached);
    // Coalesce identical pending jobs.
    for (final j in _queue) {
      if (j.page == page && j.width == w) return j.completer.future;
    }
    final job = _Job(page, w, isWanted);
    _queue.add(job);
    _pump();
    return job.completer.future;
  }

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      await open();
      while (_queue.isNotEmpty) {
        final job = _queue.removeLast(); // newest first
        if (job.isWanted != null && !job.isWanted!()) {
          job.completer.complete(null);
          continue;
        }
        final key = '${job.page}@${job.width}';
        final cache = job.width > 1100 ? _large : _small;
        final hit = cache.get(key);
        if (hit != null) {
          job.completer.complete(hit);
          continue;
        }
        try {
          final page = await _doc!.getPage(job.page);
          try {
            final h = job.width * page.height / page.width;
            final img = await page.render(
              width: job.width.toDouble(),
              height: h.roundToDouble(),
              format: PdfPageImageFormat.jpeg,
              backgroundColor: '#FFFFFF',
              quality: job.width > 1100 ? 90 : 85,
            );
            final bytes = img?.bytes;
            if (bytes != null) cache.put(key, bytes);
            job.completer.complete(bytes);
          } finally {
            await page.close();
          }
        } catch (e, st) {
          debugPrint('Render failed p${job.page}: $e\n$st');
          job.completer.complete(null);
        }
      }
    } catch (e) {
      debugPrint('Could not open book: $e');
      for (final j in _queue) {
        j.completer.complete(null);
      }
      _queue.clear();
    } finally {
      _running = false;
    }
  }

  @override
  Future<void> close() async {
    await _doc?.close();
    _doc = null;
  }
}

class _Lru<K, V> {
  _Lru(this.capacity);
  final int capacity;
  final _map = <K, V>{}; // insertion ordered

  V? get(K k) {
    final v = _map.remove(k);
    if (v != null) _map[k] = v;
    return v;
  }

  void put(K k, V v) {
    _map.remove(k);
    _map[k] = v;
    while (_map.length > capacity) {
      _map.remove(_map.keys.first);
    }
  }
}
