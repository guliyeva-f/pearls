import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/quote.dart';
import '../services/storage_service.dart';
import '../utils/date_formatter.dart';

class AddEditScreen extends StatefulWidget {
  final Quote? quote;

  const AddEditScreen({super.key, this.quote});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  static const _uuid = Uuid();

  List<String> _tags = [];

  bool get _isEditing => widget.quote != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _textController.text = widget.quote!.text;
      _tags = List.from(widget.quote!.tags);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag(String input) {
    final tag = input.trim().replaceAll('#', '').replaceAll(',', '').trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _tagInputController.clear();
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _copyText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      const message = 'Kopyalandı';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            message,
            textAlign: TextAlign.center,
          ),
          backgroundColor: const Color(0xFF6B5C48),
          behavior: SnackBarBehavior.floating,
          width: _snackBarWidth(context, message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  double _snackBarWidth(BuildContext context, String message) {
    const textStyle = TextStyle(fontSize: 14);
    final textPainter = TextPainter(
      text: TextSpan(text: message, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final calculatedWidth = textPainter.width + 48; 
    final maxWidth = MediaQuery.of(context).size.width - 40;
    return calculatedWidth.clamp(0, maxWidth);
  }

  Future<void> _save() async {
    if (_tagInputController.text.trim().isNotEmpty) {
      _addTag(_tagInputController.text);
    }
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      if (_isEditing) {
        final updated = widget.quote!.copyWith(text: text, tags: _tags);
        await _storage.updateQuote(updated);
      } else {
        final newQuote = Quote(
          id: _uuid.v4(),
          text: text,
          tags: _tags,
          date: DateTime.now(),
        );
        await _storage.addQuote(newQuote);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Xəta baş verdi, yenidən cəhd edin'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteDate = _isEditing ? widget.quote!.date : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'İncini dəyiş' : 'Yeni inci 🤍'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined, color: Color(0xFF6B5C48)),
            onPressed: _copyText,
            tooltip: 'Kopyala',
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF6B5C48)),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing && quoteDate != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFFA0906E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.format(quoteDate),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA0906E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              '✨ İnci',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8A7A65),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 8,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2E2418),
                height: 1.6,
              ),
              decoration: const InputDecoration(hintText: 'İncini yaz...'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Teqlər',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8A7A65),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBE0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map(
                            (tag) => Chip(
                              label: Text('#$tag'),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => _removeTag(tag),
                              deleteIconColor: const Color(0xFF6B5C48),
                              backgroundColor: const Color(0xFFE8E0D0),
                              labelStyle: const TextStyle(
                                color: Color(0xFF6B5C48),
                                fontSize: 13,
                              ),
                              side: BorderSide.none,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _tagInputController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2E2418),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'teq əlavə et...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.endsWith(' ')) {
                        _addTag(value);
                      }
                    },
                    onSubmitted: _addTag,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✨ boşluq və ya enter ilə əlavə olunur',
              style: TextStyle(fontSize: 12, color: Color(0xFFA0906E)),
            ),
          ],
        ),
      ),
    );
  }
}
