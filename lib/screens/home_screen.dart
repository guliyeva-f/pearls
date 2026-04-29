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

  List<Quote> _quotes = [];
  String? _selectedTag;
  bool _showFavourites = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    final quotes = await _storage.loadQuotes();
    setState(() => _quotes = quotes);
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
    for (final q in imported) {
      await _storage.addQuote(q);
    }
    _loadQuotes();
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
            fontSize: 13,
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
                          ...tagCounts.entries.map((e) => _buildSheetChip(
                                '#${e.key} (${e.value})',
                                _selectedTag == e.key,
                                () {
                                  setState(() {
                                    _selectedTag =
                                        _selectedTag == e.key ? null : e.key;
                                  });
                                  Navigator.pop(context);
                                },
                              )),
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

  @override
  Widget build(BuildContext context) {
    final tagCounts = _tagCounts;
    final topTags = tagCounts.entries.take(2).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pearls'),
        actions: [
          IconButton(
            icon: Icon(
              _showFavourites ? Icons.favorite : Icons.favorite_border,
              color: _showFavourites
                  ? const Color(0xFFC9785A)
                  : const Color(0xFF6B5C48),
            ),
            onPressed: () => setState(() => _showFavourites = !_showFavourites),
          ),
          IconButton(
            icon: const Icon(Icons.upload_outlined, color: Color(0xFF6B5C48)),
            onPressed: _exportQuotes,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Color(0xFF6B5C48)),
            onPressed: _importQuotes,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tagCounts.isNotEmpty)
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
                    ...topTags.map((e) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildChip(
                            '#${e.key} (${e.value})',
                            _selectedTag == e.key,
                            () => setState(() {
                              _selectedTag =
                                  _selectedTag == e.key ? null : e.key;
                            }),
                          ),
                        )),
                    if (tagCounts.length > 5) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAllTagsSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
                                '${tagCounts.length - 5}',
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
                ? const Center(
                    child: Text(
                      'Hələ inci yoxdur 🤍',
                      style: TextStyle(
                        color: Color(0xFFA0906E),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => CustomPaint(
                      painter: _DashedLinePainter(),
                    ),
                    itemBuilder: (context, index) {
                      final quote = _filtered[index];
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
                                    Text(
                                      quote.text,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2E2418),
                                        height: 1.5,
                                      ),
                                    ),
                                    if (quote.tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        children: quote.tags
                                            .map((t) => Text(
                                                  '#$t',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFFA0906E),
                                                  ),
                                                ))
                                            .toList(),
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
      floatingActionButton: Tooltip(
        message: '🤍',
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditScreen()),
            );
            _loadQuotes();
          },
          child: const Icon(Icons.add),
        ),
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