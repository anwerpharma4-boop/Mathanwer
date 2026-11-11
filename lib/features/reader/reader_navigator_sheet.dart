import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import 'page_image.dart';

/// Searches page descriptions/keywords. A number jumps to that page.
List<int> searchPages(String query, int pageCount) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];
  final n = int.tryParse(q);
  final out = <int>[];
  if (n != null && n >= 1 && n <= pageCount) out.add(n);
  final terms = q.split(RegExp(r'\s+'));
  for (var p = 1; p <= pageCount; p++) {
    if (out.contains(p)) continue;
    final text = pageSearchText(p);
    if (terms.every(text.contains)) out.add(p);
  }
  return out;
}

Future<int?> showReaderNavigator(BuildContext context, {required int currentPage}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _NavigatorSheet(currentPage: currentPage),
    ),
  );
}

class _NavigatorSheet extends StatefulWidget {
  const _NavigatorSheet({required this.currentPage});
  final int currentPage;

  @override
  State<_NavigatorSheet> createState() => _NavigatorSheetState();
}

class _NavigatorSheetState extends State<_NavigatorSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final count = services.book.pageCount;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
        TabBar(tabs: [
          Tab(icon: const Icon(Icons.grid_view_rounded), text: context.tr('thumbnails')),
          Tab(icon: const Icon(Icons.bookmarks_rounded), text: context.tr('bookmarks')),
          Tab(icon: const Icon(Icons.search_rounded), text: context.tr('search')),
        ]),
        Expanded(
          child: TabBarView(children: [
            _thumbnails(context, count),
            _bookmarks(context),
            _search(context, count),
          ]),
        ),
      ]),
    );
  }

  Widget _thumbnails(BuildContext context, int count) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 130).floor().clamp(3, 8);
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: 0.62,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        // Start near the current page.
        itemCount: count,
        itemBuilder: (context, i) => _Thumb(page: i + 1, selected: i + 1 == widget.currentPage),
      );
    });
  }

  Widget _bookmarks(BuildContext context) {
    final progress = AppScope.of(context).progress;
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final marks = progress.bookmarks.toList()..sort();
        if (marks.isEmpty) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(context.tr('noBookmarks'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final p in marks)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bookmark_rounded, color: AppColors.coral),
                  title: Text('${context.tr('page')} $p'),
                  subtitle: EnglishContent(child: Text(describePage(p))),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => progress.toggleBookmark(p),
                  ),
                  onTap: () => Navigator.of(context).pop(p),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _search(BuildContext context, int count) {
    final results = searchPages(_query.text, count);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          key: const ValueKey('pageSearchField'),
          controller: _query,
          autofocus: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.tr('search'),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (results.isNotEmpty) Navigator.of(context).pop(results.first);
          },
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, i) {
            final p = results[i];
            return ListTile(
              leading: CircleAvatar(child: Text('$p')),
              title: EnglishContent(child: Text(describePage(p))),
              onTap: () => Navigator.of(context).pop(p),
            );
          },
        ),
      ),
    ]);
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.page, required this.selected});
  final int page;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final marked = AppScope.of(context).progress.isBookmarked(page);
    return InkWell(
      onTap: () => Navigator.of(context).pop(page),
      borderRadius: BorderRadius.circular(12),
      child: Column(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AspectRatio(
              aspectRatio: 1 / AppScope.of(context).book.aspectRatio,
              child: PdfPageImage(page: page, targetWidthPx: 90 * dpr),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (marked) const Icon(Icons.bookmark_rounded, size: 14, color: AppColors.coral),
          Text('$page', style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
        ]),
      ]),
    );
  }
}
