import 'dart:ffi';
import 'package:meta/meta.dart';
import '../bindings/ffi_base.dart';
import '../bindings/ffi_util.dart';
import 'value.dart';
import 'engine.dart';

typedef Dart_C_Handler(
    {Pointer<JSContext> context, JS_Value this_val, List<JS_Value> args, Pointer result_ptr});

typedef Dart_Function_Handler(List args, Pointer<JSContext> context, JS_Value this_val);

abstract class DartCallback_ {
  final JSEngine engine;
  final String name;
  final Dart_Function_Handler handler;
  get callback_name;
  get callback_handler;
  get callback_wrapper;

  DartCallback_(this.engine, this.name, this.handler);

  wrapper_func(
      {Pointer<JSContext> context, JS_Value this_val, List<JS_Value> args, Pointer result_ptr});
}

class DartCallback implements DartCallback_ {
  DartCallback(
      {@required JSEngine this.engine,
      @required String this.name,
      @required Dart_Function_Handler this.handler});

  void wrapper_func(
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
        return;
      }
    } catch (e) {
      throw e;
    }
  }

  @override
  JSEngine engine;

  @override
  Dart_Function_Handler handler;

  @override
  String name;

  @override
  get callback_name => name;

  @override
  get callback_handler => handler;

  @override
  get callback_wrapper => wrapper_func;
}
