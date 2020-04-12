import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as PathProvider;

void main() {
  runApp(MaterialApp(
    title: 'Todo',
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<TaskTodo> _list = [];
  final TextEditingController _todoController = TextEditingController();

  int _lastRemovedIndex = -1;
  TaskTodo _lastRemoved = null;

  @override
  void initState() {
    super.initState();

    _readData().then((item) {
      setState(() {
        _list = item;
      });
    });
  }

  Future<File> _getFile() async {
    final directory = await PathProvider.getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    List<Map<String, dynamic>> listMap = [];

    for (final item in _list) {
      Map<String, dynamic> map = {'task': item.task, 'ok': item.ok};

      listMap.add(map);
    }

    String data = json.encode(listMap);
    File file = await _getFile();

    return file.writeAsString(data);
  }

  Future<List<TaskTodo>> _readData() async {
    try {
      final file = await _getFile();
      final contentText = await file.readAsString();
      final contentJson = json.decode(contentText);
      final List<TaskTodo> list = [];

      if (contentText.isEmpty) {
        return list;
      }

      for (final item in contentJson) {
        list.add(TaskTodo(item['task'], item['ok']));
      }

      return list;
    } catch (e) {
      print(e);
      return [];
    }
  }

  void _addTodo() {
    TaskTodo todo = TaskTodo((_todoController.text), false);

    setState(() {
      _list.add(todo);
      _todoController.clear();
      _saveData();
    });
  }

  Future<void> _refresh() async{
    await Future.delayed(Duration( seconds: 1));



    setState(() {
      _list.sort((a, b){
        return (a.ok && !b.ok)?1:(!a.ok && b.ok)?-1:0;
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Lista de Tarefas'),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      decoration: InputDecoration(
                          labelText: 'Nova Tarefa',
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  RaisedButton(
                    child: Text('Add'),
                    color: Colors.blueAccent,
                    textColor: Colors.white,
                    onPressed: _addTodo,
                  )
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _list.length,
                  itemBuilder: _buildItem),
            ))
          ],
        ));
  }

  Widget _buildItem(BuildContext context, int index) {
    final task = _list[index];
    return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        onDismissed: (direction) {
          _lastRemovedIndex = index;
          _lastRemoved = new TaskTodo(task.task, task.ok);

          setState(() {
            _list.removeAt(index);
          });

          _saveData();

          final snack = SnackBar(
            content: Text('Tarefa \"${_lastRemoved.task}\" removida!'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _list.insert(_lastRemovedIndex, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        },
        background: Container(
            color: Colors.redAccent,
            child: Align(
              alignment: Alignment(-0.9, 0),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            )),
        direction: DismissDirection.startToEnd,
        child: CheckboxListTile(
          title: Text(task.task),
          value: task.ok,
          secondary:
              CircleAvatar(child: Icon(task.ok ? Icons.check : Icons.error)),
          onChanged: (value) {
            setState(() {
              _list[index].ok = !_list[index].ok;
              _saveData();
            });
          },
        ));
  }
}

class TaskTodo {
  String task;
  bool ok;

  TaskTodo(this.task, this.ok);
}
