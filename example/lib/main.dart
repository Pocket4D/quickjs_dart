import 'package:flutter/material.dart';
import 'package:quickjs_dart/quickjs_dart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final JSEngine engine = JSEngine.start();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'quickjs_dart',
      home: JSEnginePage(engine),
    );
  }
}

class JSEnginePage extends StatefulWidget {
  final JSEngine engine;
  JSEnginePage(this.engine);

  @override
  _JSEnginePageState createState() => _JSEnginePageState();
}

class _JSEnginePageState extends State<JSEnginePage> {
  String _platformVersion = 'Unknown';

  TextEditingController _jsInputController = TextEditingController(text: '1 + 1');
  String _result;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Running on: $_platformVersion\n'),
            Divider(
              height: 10,
            ),
            Text('JS eval is: $_result'),
            Divider(
              height: 10,
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                maxLines: 10,
                controller: _jsInputController,
              ),
            ),
            Divider(
              height: 10,
            ),
            MaterialButton(
              color: Colors.black,
              textColor: Colors.white,
              minWidth: 200,
              height: 60,
              onPressed: () {
                // print(_jsInputController);
                var toEvalString = _jsInputController.text;
                var jsVal = widget.engine.evalScript("$toEvalString");
                if (!jsVal.isValid()) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Eval Javascript Fail"),
                        content: Text("Please change your script"),
                        actions: [
                          FlatButton(
                              child: Text(
                                "OK",
                                style: TextStyle(fontSize: 18),
                              ),
                              onPressed: () => Navigator.pop(context))
                        ],
                      );
                    },
                  );
                } else {
                  setState(() {
                    _result = jsVal.toJSONString();
                  });
                }

                jsVal.free();
              },
              child: Text("lets eval js"),
            )
          ],
        ),
      ),
    );
  }

  @override
  dispose() {
    super.dispose();
    widget.engine.stop();
  }
}
