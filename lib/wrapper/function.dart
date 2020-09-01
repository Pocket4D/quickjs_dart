import 'dart:ffi';
import 'package:meta/meta.dart';

import '../core.dart';

typedef Dart_Sync_Handler({Pointer<JSContext> context, JS_Value this_val, List<JS_Value> args});

typedef Dart_Function_Handler(List args, Pointer<JSContext> context, JS_Value this_val);

abstract class Dart_Callback {
  JSEngine engine;
  String name;
  Dart_Function_Handler handler;

  get callback_name => name;
  get callback_handler => handler;
  get callback_wrapper => wrapper_func;
  Dart_Callback({@required this.engine, @required this.name, @required this.handler});

  JS_Value wrapper_func({Pointer<JSContext> context, JS_Value this_val, List<JS_Value> args}) {
    try {
      List _dart_args =
          args != null ? args.map((element) => engine.from_js_val(element)).toList() : null;
      var handler_result = handler(_dart_args, context, this_val);
      if (handler_result is Future) {
        var newPromise = engine.global_promise.call_js(null);
        handler_result.then((value) {
          newPromise.getProperty("resolve").call_js([engine.to_js_val(value)]);
        }).catchError((e) {
          newPromise.getProperty("reject").call_js([engine.newString(e.toString())]);
        });
        return newPromise.getProperty("promise");
      } else {
        return engine.to_js_val(handler_result);
      }
    } catch (e) {
      throw e;
    }
  }
}

class Dart_JS_Callback extends Dart_Callback {
  Dart_JS_Callback(
      {@required JSEngine engine, @required String name, @required Dart_Function_Handler handler})
      : super(engine: engine, name: name, handler: handler);
}
