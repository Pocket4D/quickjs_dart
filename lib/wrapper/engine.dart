import 'dart:ffi';
import 'dart:isolate';
import '../bindings/ffi_base.dart';
import '../bindings/ffi_util.dart';
import '../bindings/util.dart';
import '../bindings/ffi_value.dart';
import 'value.dart';
import 'function.dart';

Map<int, Dart_Handler> dart_handler_map;

class JSEngine {
  /// runtime pointer
  Pointer<JSRuntime> _rt;

  /// context pointer
  Pointer<JSContext> _ctx;

  /// context getter
  Pointer<JSContext> get context => _ctx;

  /// global object getter
  JS_Value get global => _globalObject();

  int _next_handler_Id = 0;

  static ReceivePort cRequests = ReceivePort()
    ..listen((message) {
      print(message);
    });

  JSEngine.start() {
    _rt = newRuntime();
    _ctx = newContext(_rt);
    initDartAPI();
    setGlobalObject("global");
    registerDartFP();
    registerDartVoidFP();
  }

  JSEngine.stop(JSEngine engine) {
    engine.stop();
  }

  void stop() {
    freeContext(_rt);
    freeRuntime(_rt);
  }

  /// Dart Api for Dynamic link, should place before function call
  void initDartAPI() {
    final initializeApi =
        dylib.lookupFunction<IntPtr Function(Pointer<Void>), int Function(Pointer<Void>)>(
            "Dart_InitializeApiDL");
    if (initializeApi(NativeApi.initializeApiDLData) != 0) {
      throw "Failed to initialize Dart API";
    }
  }

  void registerDartFP() {
    final dartCallbackPointer = Pointer.fromFunction<
        Pointer Function(Pointer<JSContext> ctx, Pointer this_val, Int32 argc, Pointer<Uint64> argv,
            Pointer func_data)>(callBackWrapper);
    registerDartCallbackFP(dartCallbackPointer);
  }

  void registerDartVoidFP() {
    final dartVoidCallbackPointer = Pointer.fromFunction<
        Void Function(Pointer<JSContext> ctx, Pointer this_val, Int32 argc, Pointer<Uint64> argv,
            Pointer func_data, Pointer result)>(voidCallBackWrapper);
    registerDartVoidCallbackFP(dartVoidCallbackPointer);
  }

  void setGlobalObject(String globalString) {
    var globalObj = _globalObject();
    globalObj.setPropertyString(globalString, globalObj);
  }

  void dispose() {
    stop();
  }

  /**
   * Convert a Javascript function into a QuickJS function value.
   */
  createNewFunction(String func_name, Dart_Handler handler) {
    final int handler_id = ++_next_handler_Id;
    if (dart_handler_map == null) {
      dart_handler_map = new Map();
    }
    dart_handler_map.putIfAbsent(handler_id, () => handler);

    installDartHook(_ctx, global.value, Utf8Fix.toUtf8(func_name), handler_id);
  }

  createNewAsyncFunction(String func_name) {
    print("Not Implemented");
  }

  static Pointer callBackWrapper(
      Pointer<JSContext> ctx, Pointer this_val, int argc, Pointer<Uint64> argv, Pointer func_data) {
    final int handler_id = ToInt64(ctx, func_data);
    final Dart_Handler handler = dart_handler_map[handler_id];

    if (handler == null) {
      throw 'QuickJS VM had no callback with id ${handler_id}';
    }

    List<Pointer> args =
        argc > 1 ? List.generate(argc, (index) => argv.elementAt(2 * index)) : [argv];

    var result = handler(ctx, this_val, args, handler_id, this_val);

    if (result is Future<dynamic>) {
      return atomToValue(ctx, 194);
    }
    return result;

    // const thisHandle = new WeakLifetime(this_ptr, this.copyJSValue, this.freeJSValue, this)
    // const argHandles = new Array<QuickJSHandle>(argc)
    // for (let i = 0; i < argc; i++) {
    //   const ptr = this.ffi.QTS_ArgvGetJSValueConstPointer(argv, i)
    //   argHandles[i] = new WeakLifetime(ptr, this.copyJSValue, this.freeJSValue, this)
    // }

    // let ownedResultPtr = 0 as JSValuePointer
    // try {
    //   let result = fn.apply(thisHandle, argHandles)
    //   if (result) {
    //     if ('error' in result && result.error) {
    //       throw result.error
    //     }
    //     const handle = result instanceof Lifetime ? result : result.value
    //     ownedResultPtr = this.ffi.QTS_DupValuePointer(this.ctx.value, handle.value)
    //     handle.dispose()
    //   }
    // } catch (error) {
    //   ownedResultPtr = this.errorToHandle(error).consume(errorHandle =>
    //     this.ffi.QTS_Throw(this.ctx.value, errorHandle.value)
    //   )
    // }

    // // Free the arguments so they can't be retained and re-used after we return.
    // if (thisHandle.alive) {
    //   thisHandle.dispose()
    // }
    // for (const argHandle of argHandles) {
    //   if (argHandle.alive) {
    //     argHandle.dispose()
    //   }
    // }

    // return ownedResultPtr as JSValuePointer
  }

  static void voidCallBackWrapper(Pointer<JSContext> ctx, Pointer this_val, int argc,
      Pointer<Uint64> argv, Pointer func_data, Pointer result_ptr) {
    final int handler_id = ToInt64(ctx, func_data);
    final Dart_Handler handler = dart_handler_map[handler_id];
    if (handler == null) {
      throw 'QuickJS VM had no callback with id ${handler_id}';
    }
    List<Pointer> args =
        argc > 1 ? List.generate(argc, (index) => argv.elementAt(2 * index)) : [argv];

    handler(ctx, this_val, args, handler_id, result_ptr);
  }

  JS_Value callFunction(JS_Value js_func_obj, JS_Value js_obj, int arg_length, JS_Value arg_value) {
    Pointer callResult = call(_ctx, js_func_obj.value, js_obj.value, arg_length, arg_value.value);
    return JS_Value(_ctx, callResult);
  }

  JS_Value dart_call_js(JS_Value this_val, List<JS_Value> params) {
    try {
      return this_val.call_js(params);
    } catch (e) {
      throw e;
    }
  }

  JS_Value dart_call_js_encode(JS_Value this_val, List<Object> params) {
    try {
      return this_val.call_js_encode(params);
    } catch (e) {
      throw e;
    }
  }

  JS_Value evalScript(String js_string) {
    var ptr = eval(context, Utf8Fix.toUtf8(js_string), js_string.length);
    return JS_Value(context, ptr);
  }

  JS_Value _globalObject() {
    return JS_Value(_ctx, getGlobalObject(_ctx));
  }

  JS_Value newInt32(int val) {
    return JS_Value.newInt32(_ctx, val);
  }

  JS_Value newBool(bool val) {
    return JS_Value.newBool(_ctx, val);
  }

  JS_Value newNull() {
    return JS_Value.newNull(_ctx);
  }

  /// make a new js_nul

  JS_Value newError() {
    return JS_Value.newError(_ctx);
  }

  /// make a new js_uint32
  JS_Value newUint32(int val) {
    return JS_Value.newUint32(_ctx, val);
  }

  /// make a new js_int64
  JS_Value newInt64(int val) {
    return JS_Value.newInt64(_ctx, val);
  }

  /// make a new js_bigInt64
  JS_Value newBigInt64(int val) {
    return JS_Value.newBigInt64(_ctx, val);
  }

  /// make a new js_bigUint64
  JS_Value newBigUint64(int val) {
    return JS_Value.newBigUint64(_ctx, val);
  }

  JS_Value newFloat64(double val) {
    return JS_Value.newFloat64(_ctx, val);
  }

  JS_Value newString(String val) {
    return JS_Value.newString(_ctx, val);
  }

  JS_Value newAtomString(String val) {
    return JS_Value.newAtomString(_ctx, val);
  }

  JS_Value newObject() {
    return JS_Value.newObject(_ctx);
  }

  JS_Value newArray() {
    return JS_Value.newArray(_ctx);
  }
}
