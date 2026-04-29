import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/storage_service.dart';

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
    final tag = input.trim().replaceAll('#', '').trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _tagInputController.clear();
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _save() async {
    if (_tagInputController.text.trim().isNotEmpty) {
      _addTag(_tagInputController.text);
    }
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_isEditing) {
      final updated = widget.quote!.copyWith(text: text, tags: _tags);
      await _storage.updateQuote(updated);
    } else {
      final newQuote = Quote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        tags: _tags,
      );
      await _storage.addQuote(newQuote);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'İncini dəyiş' : 'Yeni inci 🤍'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              maxLines: 6,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2E2418),
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: 'İncini yaz...',
              ),
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
                          .map((tag) => Chip(
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
                                    horizontal: 4, vertical: 0),
                              ))
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