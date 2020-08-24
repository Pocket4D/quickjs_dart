import 'dart:ffi';

import '../ffi.dart';

class Dart_CallBack {
  Pointer<JSContext> _ctx;
  Pointer _this_val;
  String func_name;
  Pointer<NativeFunction> func;
  int length;

  final dartCallbackPointer = Pointer.fromFunction<
      Pointer Function(Handle handler, Pointer<JSContext> ctx, Pointer this_val, Int32 argc,
          Pointer argv)>(doClosureCallback);

  final dartAsyncCallbackPointer = Pointer.fromFunction<
      Void Function(Handle handler, Pointer<JSContext> ctx, Pointer this_val, Int32 argc,
          Pointer argv)>(doClosureAsyncCallback);

  Dart_CallBack(this._ctx, this._this_val, this.func_name, this.length);

  createFunc() {
    registerDartCallbackFP(dartCallbackPointer);
    // save_dart_handler(dart_handler);
    // installDartHook(_ctx, _this_val, Utf8Fix.toUtf8(func_name), length, dart_handler);
  }

  Pointer dart_handler(Pointer<JSContext> ctx, Pointer this_val, int argc, List<Pointer> args) {
    // var argvString = Utf8Fix.fromUtf8(toCString(ctx, args[0]));
    // print({"argvString": argvString});
    var some = newString(ctx, Utf8Fix.toUtf8("fuck"));
    return some;
  }

  // void dart_async_handler(Pointer<JSContext> ctx, Pointer this_val, int argc, List<Pointer> args) {
  //   var argvString = Utf8Fix.fromUtf8(toCString(ctx, args[0]));
  //   var some = newString(ctx, Utf8Fix.toUtf8("${argvString}+fuck"));
  //   setDartAsyncResult(some);
  // }

  static Pointer doClosureCallback(
      Object callback, Pointer<JSContext> ctx, Pointer this_val, int argc, Pointer<Uint64> argv) {
    print({callback, ctx, this_val, argc, argv});
    List<Pointer> args =
        argc > 1 ? List.generate(argc, (index) => argv.elementAt(2 * index)) : [argv];

    final callbackFunc = callback as Pointer Function(
        Pointer<JSContext> ctx, Pointer this_val, int argc, List<Pointer> args);

    final result = callbackFunc(ctx, this_val, args.length, args);
    return result;
  }

  static void doClosureAsyncCallback(
      Object callback, Pointer<JSContext> ctx, Pointer this_val, int argc, Pointer<Uint64> argv) {
    List<Pointer> args =
        argc > 1 ? List.generate(argc, (index) => argv.elementAt(2 * index)) : [argv];
    final callbackFunc = callback as void Function(
        Pointer<JSContext> ctx, Pointer this_val, int argc, List<Pointer> args);

    callbackFunc(ctx, this_val, args.length, args);
  }
}
