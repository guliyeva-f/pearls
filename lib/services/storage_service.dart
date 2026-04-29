import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote.dart';

class StorageService {
  static const String _key = 'quotes';

  Future<List<Quote>> loadQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_key) ?? [];
    return rawList.map((e) => Quote.fromMap(jsonDecode(e))).toList();
  }

  Future<void> saveQuotes(List<Quote> quotes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList =
        quotes.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }

  Future<void> addQuote(Quote quote) async {
    final quotes = await loadQuotes();
    quotes.add(quote);
    await saveQuotes(quotes);
  }

  Future<void> updateQuote(Quote updated) async {
    final quotes = await loadQuotes();
    final index = quotes.indexWhere((q) => q.id == updated.id);
    if (index != -1) {
      quotes[index] = updated;
      await saveQuotes(quotes);
    }
  }
}