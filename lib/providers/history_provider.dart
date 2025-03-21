import 'package:flutter/foundation.dart';
import '../models/history_item.dart';  // Updated import

class HistoryProvider with ChangeNotifier {
  final List<HistoryItem> _items = [];

  List<HistoryItem> get items => [..._items];

  void addItem(HistoryItem newItem) {
    _items.insert(0, newItem);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }
}