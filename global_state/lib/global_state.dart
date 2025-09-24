library global_state;

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

/// Data model for a single counter.
class CounterData {
  final String id;
  int value;
  Color color;
  String label;

  CounterData({
    required this.id,
    this.value = 0,
    Color? color,
    String? label,
  })  : color = color ?? Colors.blue,
        label = label ?? 'Counter';
}

class GlobalState extends Model {
  final List<CounterData> _counters = [];

  List<CounterData> get counters => List.unmodifiable(_counters);

  /// Add a new counter with optional label and color
  void addCounter({String? label, Color? color}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _counters.add(CounterData(id: id, value: 0, color: color, label: label));
    notifyListeners();
  }

  /// Remove counter by id
  void removeCounter(String id) {
    _counters.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Increment a specific counter by id
  void increment(String id) {
    final c = _counters.firstWhere((e) => e.id == id, orElse: () => throw 'Counter not found');
    c.value++;
    notifyListeners();
  }

  /// Decrement a specific counter by id (no negative values)
  void decrement(String id) {
    final c = _counters.firstWhere((e) => e.id == id, orElse: () => throw 'Counter not found');
    if (c.value > 0) {
      c.value--;
      notifyListeners();
    }
  }

  void clearAll() {
    _counters.clear();
    notifyListeners();
  }
}
