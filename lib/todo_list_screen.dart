import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

final supabase = Supabase.instance.client;

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _todoStream = supabase
      .from('todos')
      .stream(primaryKey: ['id'])
      .eq('user_id', supabase.auth.currentUser!.id)
      .order('created_at', ascending: false);

  void _showAddTaskSheet() {
    final taskController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'What do you need to do?',
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Add Task'),
                  onPressed: () async {
                    final task = taskController.text.trim();
                    if (task.isNotEmpty) {
                      await supabase.from('todos').insert({'task': task});
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await supabase.auth.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _todoStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "All clear!",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  Text(
                    "Add a new task to get started.",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          final todos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Dismissible(
                key: Key(todo['id'].toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await supabase.from('todos').delete().eq('id', todo['id']);
                },
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.white,
                  ),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    leading: IconButton(
                      icon: Icon(
                        todo['is_complete']
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            todo['is_complete']
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                      onPressed: () async {
                        await supabase
                            .from('todos')
                            .update({'is_complete': !todo['is_complete']})
                            .eq('id', todo['id']);
                      },
                    ),
                    title: Text(
                      todo['task'],
                      style: TextStyle(
                        decoration:
                            todo['is_complete']
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        color: todo['is_complete'] ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }
}
