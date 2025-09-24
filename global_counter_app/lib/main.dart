import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:global_state/global_state.dart';

void main() {
  runApp(GlobalCounterApp());
}

class GlobalCounterApp extends StatelessWidget {
  GlobalCounterApp({super.key}) : _model = GlobalState() {

    _model.addCounter(label: 'First', color: Colors.indigo);
  }

  final GlobalState _model;

  @override
  Widget build(BuildContext context) {
    return ScopedModel<GlobalState>(
      model: _model,
      child: MaterialApp(
        title: 'Global Counter App',
        theme: ThemeData(useMaterial3: false),
        home: const CounterListPage(),
      ),
    );
  }
}

class CounterListPage extends StatelessWidget {
  const CounterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<GlobalState>(
      builder: (context, child, model) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Global Counters'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddDialog(context, model),
                tooltip: 'Add counter',
              ),
            ],
          ),
          body: model.counters.isEmpty
              ? const Center(child: Text('No counters yet. Tap + to add one.'))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: model.counters.length,
                  onReorder: (oldIndex, newIndex) {
                    // forward reorder to the global state
                    model.reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final counter = model.counters[index];
                    // ReorderableListView requires each child to have a key.
                    return CounterTile(
                      key: ValueKey(counter.id),
                      counterId: counter.id,
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddDialog(context, model),
            child: const Icon(Icons.add),
            tooltip: 'Add counter',
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, GlobalState model) {
    final labelCtrl = TextEditingController(text: 'Counter ${model.counters.length + 1}');
    Color selected = Colors.primaries[model.counters.length % Colors.primaries.length].shade500;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setState) {
          return AlertDialog(
            title: const Text('Add Counter'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: Colors.primaries.take(8).map((c) {
                    final col = c.shade500;
                    final isSelected = col == selected;
                    return GestureDetector(
                      onTap: () => setState(() => selected = col),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: col,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSelected ? Colors.black : Colors.black12, width: isSelected ? 2 : 1),
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  model.addCounter(label: labelCtrl.text, color: selected);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }
}

extension on GlobalState {
  void reorder(int oldIndex, int newIndex) {}
}

class CounterTile extends StatefulWidget {
  final String counterId;

  const CounterTile({required Key key, required this.counterId}) : super(key: key);

  @override
  State<CounterTile> createState() => _CounterTileState();
}

class _CounterTileState extends State<CounterTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flash() {
    _controller.forward(from: 0).then((_) {
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<GlobalState>(
      builder: (context, child, model) {
        final c = model.counters.firstWhere((e) => e.id == widget.counterId, orElse: () => CounterData(id: widget.counterId));
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: c.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.color.withOpacity(0.24)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: c.color,
              child: Text('${c.value}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(c.label),
            subtitle: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    model.increment(c.id);
                    _flash(); // local UI feedback
                  },
                  child: const Text('Increment'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    model.decrement(c.id);
                    _flash();
                  },
                  child: const Text('Decrement'),
                ),
                const SizedBox(width: 12),
                // small animated value display (local AnimatedSwitcher)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text('Value: ${c.value}', key: ValueKey<int>(c.value)),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => model.removeCounter(c.id),
            ),
          ),
        );
      },
    );
  }
}
