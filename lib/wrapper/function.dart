import 'dart:ffi';
import 'package:meta/meta.dart';
import '../bindings/ffi_base.dart';
import '../bindings/ffi_util.dart';
import 'value.dart';
import 'engine.dart';

typedef DartCHandler(
    {Pointer<JSContext> context, JSValue thisVal, List<JSValue> args, Pointer resultPtr});

typedef DartFunctionHandler(List args, Pointer<JSContext> context, JSValue thisVal);

// ignore: camel_case_types
abstract class DartCallbackClass {
  final JSEngine engine;
  final String name;
  final DartFunctionHandler handler;
  get callbackName;
  get callbackHandler;
  get callbackWrapper;

  DartCallbackClass(this.engine, this.name, this.handler);

  wrapperFunc({Pointer<JSContext> context, JSValue thisVal, List<JSValue> args, Pointer resultPtr});
}

class DartCallback implements DartCallbackClass {
  DartCallback({@required this.engine, @required this.name, @required this.handler});

  void wrapperFunc(
      {Pointer<JSContext> context, JSValue thisVal, List<JSValue> args, Pointer resultPtr}) {
    try {
      List _dartArgs =
          args != null ? args.map((element) => engine.fromJSVal(element)).toList() : null;
      var handlerResult = handler(_dartArgs, context, thisVal);
      // print(handlerResult);
      if (handlerResult == null) {
        jsValueCopy(resultPtr, engine.newNull().value);
        return;
      } else {
        if (!(handlerResult is Future)) {
          jsValueCopy(resultPtr, engine.toJSVal(handlerResult).value);
          return;
        }
        var newPromise = engine.globalPromise.callJS(null);
        handlerResult.then((value) {
          newPromise.getProperty("resolve").callJS([engine.toJSVal(value)]);
          newPromise.free();
          JSEngine.loop(engine);
        }).catchError((e) {
          newPromise.getProperty("reject").callJS([engine.newString(e.toString())]);
          newPromise.free();
          JSEngine.loop(engine);
        });
        jsValueCopy(resultPtr, newPromise.getProperty("promise").value);
        return;
      }
    } catch (e) {
      throw e;
    }
  }

  @override
  JSEngine engine;

  @override
  DartFunctionHandler handler;

  @override
  String name;

  @override
  get callbackName => name;

  @override
  get callbackHandler => handler;

  @override
  get callbackWrapper => wrapperFunc;
}
