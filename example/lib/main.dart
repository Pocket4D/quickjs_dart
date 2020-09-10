import 'package:flutter/material.dart';
import 'package:quickjs_dart/quickjs_dart.dart';

// import 'package:flutter/services.dart' show rootBundle;

// Future<String> loadAsset() async {
//   return await rootBundle.loadString('assets/js/framework.js');
// }

void main() {
  JSEngine();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'quickjs_dart',
      home: JSEnginePage(),
    );
  }
}

class JSEnginePage extends StatefulWidget {
  @override
  _JSEnginePageState createState() => _JSEnginePageState();
}

class _JSEnginePageState extends State<JSEnginePage> {
  TextEditingController _jsInputController = TextEditingController(text: '1 + 1');
  String _result;
  // JS_Value _framework;

  @override
  void initState() {
    super.initState();
    // evalFramework();
  }

  // evalFramework() async {
  //   var jsFile = await loadAsset();
  //   var framework = JSEngine.instance.evalScript(jsFile);
  //   print(framework.isValid());
  //   setState(() {
  //     _framework = framework;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Quickjs Example'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
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
                var toEvalString = _jsInputController.text.replaceAll(RegExp("[“”‘’]"), "\"");
                var jsVal = JSEngine.instance.evalScript(toEvalString);
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
    JSEngine.instance.stop();
  }
}
