import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'models/task.dart';
import 'utils/DatabaseHelper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do App',
      home: TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late List<Task> tasks;

  @override
  void initState() {
    super.initState();
    tasks = [];
    fetchTasks();
  }

  void fetchTasks() async {
    final db = await DatabaseHelper.instance.database;
    final taskList = await db.query('tasks');
    setState(() {
      tasks = taskList.map((taskMap) {
        final createdAtString = taskMap['created_at'] as String;
        final createdAt = DateTime.parse(createdAtString);
        return Task(
          id: taskMap['id'] as int,
          title: taskMap['title'] as String,
          isCompleted: taskMap['is_completed'] == 1,
          createdAt: createdAt,
        );
      }).toList();
    });
  }

  void toggleTaskCompletion(int taskId, bool isCompleted) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'tasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
    fetchTasks();
  }

  void addTask(String title) async {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'tasks',
      {
        'title': title,
        'is_completed': 0,
        'created_at': formattedDate,
      },
    );
    fetchTasks();
  }

  void _showAddTaskDialog(BuildContext context) {
    String newTaskTitle = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            onChanged: (value) {
              newTaskTitle = value;
            },
            decoration: const InputDecoration(
              hintText: 'Task title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newTaskTitle.isNotEmpty) {
                  addTask(newTaskTitle);
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do App'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                toggleTaskCompletion(task.id, !task.isCompleted);
              },
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            subtitle: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(task.createdAt),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${tasks.where((task) => !task.isCompleted).length} Tasks Pending'),
              ElevatedButton(
                onPressed: () {
                  _showAddTaskDialog(context);
                },
                child: const Text('Add Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
