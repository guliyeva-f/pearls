import 'dart:math';
import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/storage_service.dart';
import '../services/export_import_service.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final ExportImportService _exportImport = ExportImportService();
  final TextEditingController _searchController = TextEditingController();

  List<Quote> _quotes = [];
  String? _selectedTag;
  bool _showFavourites = false;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _hasShownDailyQuote = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    final quotes = await _storage.loadQuotes();
    setState(() => _quotes = quotes);
    if (!_hasShownDailyQuote && quotes.isNotEmpty && mounted) {
      _hasShownDailyQuote = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDailyQuoteDialog();
      });
    }
  }

  Map<String, int> get _tagCounts {
    final counts = <String, int>{};
    for (final q in _quotes) {
      for (final tag in q.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  List<Quote> get _filtered {
    return _quotes.where((q) {
      if (_showFavourites && !q.isFavourite) return false;
      if (_selectedTag != null && !q.tags.contains(_selectedTag)) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final textMatch = q.text.toLowerCase().contains(query);
        final tagMatch = q.tags.any((t) => t.toLowerCase().contains(query));
        if (!textMatch && !tagMatch) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _toggleFavourite(Quote quote) async {
    final updated = quote.copyWith(isFavourite: !quote.isFavourite);
    await _storage.updateQuote(updated);
    _loadQuotes();
  }

  Future<void> _exportQuotes() async {
    await _exportImport.exportQuotes(_quotes);
  }

  Future<void> _importQuotes() async {
    final imported = await _exportImport.importQuotes();
    if (imported.isEmpty) return;
    await _storage.addQuotes(imported);
    _loadQuotes();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) return Text(text, style: style);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    if (!lowerText.contains(lowerQuery)) return Text(text, style: style);

    final spans = <TextSpan>[];
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: style.copyWith(
            backgroundColor: const Color(0xFFDEB96A).withValues(alpha: 0.35),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E2418),
          ),
        ),
      );
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return RichText(text: TextSpan(children: spans));
  }

  void _showDailyQuoteDialog() {
    if (_quotes.isEmpty) return;
    final random = Random();
    int currentIndex = random.nextInt(_quotes.length);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final quote = _quotes[currentIndex];
            return Dialog(
              backgroundColor: const Color(0xFFFAF7F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.80,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🤍', style: TextStyle(fontSize: 20)),
                          Text(
                            ' Günün incisi ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3A2E1E),
                            ),
                          ),
                          Text('🤍 ', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EBE0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quote.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 26, 21, 14),
                                    height: 1.6,
                                  ),
                                ),
                                if (quote.tags.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    children: quote.tags
                                        .map(
                                          (t) => Text(
                                            '#$t',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFA0906E),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              int newIndex;
                              do {
                                newIndex = random.nextInt(_quotes.length);
                              } while (newIndex == currentIndex &&
                                  _quotes.length > 1);
                              setDialogState(() => currentIndex = newIndex);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E0D0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shuffle_rounded,
                                    size: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B5C48),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Dəyiş',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 74, 63, 49),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6B5C48),
                            ),
                            child: const Text('Bağla'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6B5C48) : const Color(0xFFE8E0D0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? const Color(0xFFFAF7F2) : const Color(0xFF6B5C48),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6B5C48) : const Color(0xFFE8E0D0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? const Color(0xFFFAF7F2) : const Color(0xFF6B5C48),
          ),
        ),
      ),
    );
  }

  void _showAllTagsSheet() {
    final tagCounts = _tagCounts;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDD4C4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bütün teqlər',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3A2E1E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          _buildSheetChip(
                            'Hamısı (${_quotes.length})',
                            _selectedTag == null && !_showFavourites,
                            () {
                              setState(() {
                                _selectedTag = null;
                                _showFavourites = false;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ...tagCounts.entries.map(
                            (e) => _buildSheetChip(
                              '#${e.key} (${e.value})',
                              _selectedTag == e.key,
                              () {
                                setState(() {
                                  _selectedTag = _selectedTag == e.key
                                      ? null
                                      : e.key;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagCounts = _tagCounts;
    final topTags = tagCounts.entries.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF2E2418), fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Axtar...',
                  hintStyle: TextStyle(color: Color(0xFFA0906E)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
              )
            : const Text('Pearls'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF6B5C48)),
              onPressed: _stopSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF6B5C48)),
              onPressed: _startSearch,
            ),
            IconButton(
              icon: Icon(
                _showFavourites ? Icons.favorite : Icons.favorite_border,
                color: _showFavourites
                    ? const Color(0xFFC9785A)
                    : const Color(0xFF6B5C48),
              ),
              onPressed: () =>
                  setState(() => _showFavourites = !_showFavourites),
            ),
            IconButton(
              icon: const Icon(Icons.upload_outlined, color: Color(0xFF6B5C48)),
              onPressed: _exportQuotes,
            ),
            IconButton(
              icon: const Icon(
                Icons.download_outlined,
                color: Color(0xFF6B5C48),
              ),
              onPressed: _importQuotes,
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tagCounts.isNotEmpty && !_isSearching)
            Container(
              width: double.infinity,
              color: const Color(0xFFF0EBE0),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip(
                      'Hamısı (${_quotes.length})',
                      _selectedTag == null && !_showFavourites,
                      () => setState(() {
                        _selectedTag = null;
                        _showFavourites = false;
                      }),
                    ),
                    ...topTags.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildChip(
                          '#${e.key} (${e.value})',
                          _selectedTag == e.key,
                          () => setState(() {
                            _selectedTag = _selectedTag == e.key ? null : e.key;
                          }),
                        ),
                      ),
                    ),
                    if (tagCounts.length > 3) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAllTagsSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFDDD4C4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '+ daha çox',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B5C48),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tagCounts.length - 3}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0906E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Nəticə tapılmadı 🔍'
                          : 'Hələ inci yoxdur 🤍',
                      style: const TextStyle(
                        color: Color(0xFFA0906E),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) =>
                        CustomPaint(painter: _DashedLinePainter()),
                    itemBuilder: (context, index) {
                      final quote = _filtered[index];
                      final highlightQuery = _searchQuery.isNotEmpty
                          ? _searchQuery
                          : (_selectedTag ?? '');
                      return InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditScreen(quote: quote),
                            ),
                          );
                          _loadQuotes();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHighlightedText(
                                      quote.text,
                                      highlightQuery,
                                      const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2E2418),
                                        height: 1.5,
                                      ),
                                    ),
                                    if (quote.tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        children: quote.tags.map((t) {
                                          final isTagMatch =
                                              highlightQuery.isNotEmpty &&
                                              t.toLowerCase().contains(
                                                highlightQuery.toLowerCase(),
                                              );
                                          return Text(
                                            '#$t',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFFA0906E),
                                              backgroundColor: isTagMatch
                                                  ? const Color(
                                                      0xFFDEB96A,
                                                    ).withValues(alpha: 0.35)
                                                  : null,
                                              fontWeight: isTagMatch
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _toggleFavourite(quote),
                                child: Icon(
                                  quote.isFavourite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 20,
                                  color: quote.isFavourite
                                      ? const Color(0xFFC9785A)
                                      : const Color(0xFFC4B49E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'daily',
            onPressed: _showDailyQuoteDialog,
            backgroundColor: const Color(0xFFC9785A),
            foregroundColor: const Color(0xFF6B5C48),
            elevation: 2,
            child: const Text('✨', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: const Color(0xFFF0EBE0),
            foregroundColor: const Color(0xFF6B5C48),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditScreen()),
              );
              _loadQuotes();
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 91, 76, 50)
      ..strokeWidth = 1;
    double x = 0;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}