import 'dart:ffi';
import 'package:meta/meta.dart';

import '../core.dart';

typedef Dart_Sync_Handler(
    {Pointer<JSContext> context, JS_Value this_val, List<JS_Value> args, Pointer result_ptr});

typedef Dart_Function_Handler(List args, Pointer<JSContext> context, JS_Value this_val);

abstract class Dart_Callback {
  JSEngine engine;
  String name;
  Dart_Function_Handler handler;

  get callback_name => name;
  get callback_handler => handler;
  get callback_wrapper => wrapper_func;
  Dart_Callback({@required this.engine, @required this.name, @required this.handler});

  wrapper_func(
      {Pointer<JSContext> context, JS_Value this_val, List<JS_Value> args, Pointer result_ptr}) {
    try {
      List _dart_args =
          args != null ? args.map((element) => engine.from_js_val(element)).toList() : null;
      var handler_result = handler(_dart_args, context, this_val);
      // print(handler_result);
      if (handler_result == null) {
        jsvalue_copy(result_ptr, engine.newNull().value);
        return;
      } else {
        if (!(handler_result is Future)) {
          jsvalue_copy(result_ptr, engine.to_js_val(handler_result).value);
          return;
        }
        var newPromise = engine.global_promise.call_js(null);
        handler_result.then((value) {
          newPromise.getProperty("resolve").call_js([engine.to_js_val(value)]);
          newPromise.free();
          JSEngine.loop(engine);
        }).catchError((e) {
          newPromise.getProperty("reject").call_js([engine.newString(e.toString())]);
          newPromise.free();
          JSEngine.loop(engine);
        });
        jsvalue_copy(result_ptr, newPromise.getProperty("promise").value);
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
